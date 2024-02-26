// RUN: circt-opt %s --canonicalize | FileCheck %s

func.func private @Bool(%arg0: i1)
func.func private @Seq(%arg0: !ltl.sequence)
func.func private @Prop(%arg0: !ltl.property)

// CHECK-LABEL: @DelayFolds
func.func @DelayFolds(%arg0: !ltl.sequence, %arg1: !ltl.property) {
  // delay(s, 0, 0) -> s
  // CHECK-NEXT: call @Seq(%arg0)
  %0 = ltl.delay %arg0, 0, 0 : !ltl.sequence
  call @Seq(%0) : (!ltl.sequence) -> ()

  // delay(delay(s, 1), 2) -> delay(s, 3)
  // CHECK-NEXT: ltl.delay %arg0, 3 :
  // CHECK-NEXT: call
  %1 = ltl.delay %arg0, 1 : !ltl.sequence
  %2 = ltl.delay %1, 2 : !ltl.sequence
  call @Seq(%2) : (!ltl.sequence) -> ()

  // delay(delay(s, 1, N), 2) -> delay(s, 3)
  // N is dropped
  // CHECK-NEXT: ltl.delay %arg0, 3 :
  // CHECK-NEXT: ltl.delay %arg0, 3 :
  // CHECK-NEXT: call
  // CHECK-NEXT: call
  %3 = ltl.delay %arg0, 1, 0 : !ltl.sequence
  %4 = ltl.delay %arg0, 1, 42 : !ltl.sequence
  %5 = ltl.delay %3, 2 : !ltl.sequence
  %6 = ltl.delay %4, 2 : !ltl.sequence
  call @Seq(%5) : (!ltl.sequence) -> ()
  call @Seq(%6) : (!ltl.sequence) -> ()

  // delay(delay(s, 1), 2, N) -> delay(s, 3)
  // N is dropped
  // CHECK-NEXT: ltl.delay %arg0, 3 :
  // CHECK-NEXT: ltl.delay %arg0, 3 :
  // CHECK-NEXT: call
  // CHECK-NEXT: call
  %7 = ltl.delay %arg0, 1 : !ltl.sequence
  %8 = ltl.delay %arg0, 1 : !ltl.sequence
  %9 = ltl.delay %7, 2, 0 : !ltl.sequence
  %10 = ltl.delay %8, 2, 42 : !ltl.sequence
  call @Seq(%9) : (!ltl.sequence) -> ()
  call @Seq(%10) : (!ltl.sequence) -> ()

  // delay(delay(s, 1, 2), 3, 0) -> delay(s, 4, 2)
  // delay(delay(s, 1, 2), 3, 5) -> delay(s, 4, 7)
  // CHECK-NEXT: ltl.delay %arg0, 4, 2 :
  // CHECK-NEXT: ltl.delay %arg0, 4, 7 :
  // CHECK-NEXT: call
  // CHECK-NEXT: call
  %11 = ltl.delay %arg0, 1, 2 : !ltl.sequence
  %12 = ltl.delay %arg0, 1, 2 : !ltl.sequence
  %13 = ltl.delay %11, 3, 0 : !ltl.sequence
  %14 = ltl.delay %12, 3, 5 : !ltl.sequence
  call @Seq(%13) : (!ltl.sequence) -> ()
  call @Seq(%14) : (!ltl.sequence) -> ()

  // prperty

  // delay(p, 0, 0) -> p
  // CHECK-NEXT: call @Prop(%arg1)
  %15 = ltl.delay %arg1, 0, 0: !ltl.property
  call @Prop(%15) : (!ltl.property) -> ()

  // CHECK-NEXT: ltl.delay %arg0, 1 : !ltl.sequence
  // CHECK-NEXT: ltl.castp {{%.+}} : !ltl.sequence
  // CHECK-NEXT: ltl.delay {{%.+}}, 2 : !ltl.property
  // CHECK-NEXT: call @Prop({{%.+}})
  %16 = ltl.delay %arg0, 1 : !ltl.sequence
  %17 = ltl.castp %16 : !ltl.sequence
  %18 = ltl.delay %17, 2 : !ltl.property
  call @Prop(%18) : (!ltl.property) -> ()
  return
}

// CHECK-LABEL: @CastpFolds
func.func @CastpFolds(%arg0: i1, %arg1: !ltl.sequence, %arg2: !ltl.property) {
  // castp(p) -> p
  // CHECK-NEXT: call @Prop(%arg2)
  %0 = ltl.castp %arg2 : !ltl.property
  call @Prop(%arg2) : (!ltl.property) -> ()

  // castp(castp(s)) -> castp(s)
  // CHECK-NEXT: ltl.castp %arg1 : !ltl.sequence
  // CHECK-NEXT: call @Prop({{%.+}})
  %1 = ltl.castp %arg1 : !ltl.sequence
  %2 = ltl.castp %1 : !ltl.property
  call @Prop(%2) : (!ltl.property) -> ()

  // Operations do not need castp.
  // not(castp(s)) -> not(s)
  // implication(s, castp(s)) -> implication(s, s)
  // eventually(castp(s)) -> eventually(s)
  // until(castp(s), castp(s)) -> until(s, s)
  // disable(castp(s), i) -> disable(s, i)
  // CHECK-NEXT: ltl.castp %arg1 : !ltl.sequence
  // CHECK-NEXT: ltl.not %arg1 : !ltl.sequence
  // CHECK-NEXT: ltl.implication %arg1, %arg1 : !ltl.sequence, !ltl.sequence
  // CHECK-NEXT: ltl.eventually %arg1 : !ltl.sequence
  // CHECK-NEXT: ltl.until %arg1, %arg1 : !ltl.sequence, !ltl.sequence
  // CHECK-NEXT: ltl.disable %arg1 if %arg0 : !ltl.sequence
  %c0 = ltl.castp %arg1 : !ltl.sequence
  %c1 = ltl.not %c0 : !ltl.property
  %c2 = ltl.implication %arg1, %c0 : !ltl.sequence, !ltl.property
  %c3 = ltl.eventually %c0 : !ltl.property
  %c4 = ltl.until %c0, %c0 : !ltl.property, !ltl.property
  %c5 = ltl.disable %c0 if %arg0 : !ltl.property
  // CHECK-NEXT: call @Prop({{%.+}})
  // CHECK-NEXT: call @Prop({{%.+}})
  // CHECK-NEXT: call @Prop({{%.+}})
  // CHECK-NEXT: call @Prop({{%.+}})
  // CHECK-NEXT: call @Prop({{%.+}})
  // CHECK-NEXT: call @Prop({{%.+}})
  call @Prop(%c0) : (!ltl.property) -> ()
  call @Prop(%c1) : (!ltl.property) -> ()
  call @Prop(%c2) : (!ltl.property) -> ()
  call @Prop(%c3) : (!ltl.property) -> ()
  call @Prop(%c4) : (!ltl.property) -> ()
  call @Prop(%c5) : (!ltl.property) -> ()

  return
}

// CHECK-LABEL: @ConcatFolds
func.func @ConcatFolds(%arg0: !ltl.sequence, %arg1: !ltl.sequence, %arg2: !ltl.sequence) {
  // concat(s) -> s
  // CHECK-NEXT: call @Seq(%arg0)
  %0 = ltl.concat %arg0 : !ltl.sequence
  call @Seq(%0) : (!ltl.sequence) -> ()

  // concat(concat(s0, s1), s2) -> concat(s0, s1, s2)
  // concat(s0, concat(s1, s2)) -> concat(s0, s1, s2)
  // concat(concat(s0, s1), s2, s0, concat(s1, s2)) -> concat(s0, s1, s2, s0, s1, s2)
  // CHECK-NEXT: ltl.concat %arg0, %arg1, %arg2 :
  // CHECK-NEXT: ltl.concat %arg0, %arg1, %arg2 :
  // CHECK-NEXT: ltl.concat %arg0, %arg1, %arg2, %arg0, %arg1, %arg2 :
  // CHECK-NEXT: call
  // CHECK-NEXT: call
  // CHECK-NEXT: call
  %1 = ltl.concat %arg0, %arg1 : !ltl.sequence, !ltl.sequence
  %2 = ltl.concat %1, %arg2 : !ltl.sequence, !ltl.sequence
  %3 = ltl.concat %arg1, %arg2 : !ltl.sequence, !ltl.sequence
  %4 = ltl.concat %arg0, %3 : !ltl.sequence, !ltl.sequence
  %5 = ltl.concat %1, %arg2, %arg0, %3 : !ltl.sequence, !ltl.sequence, !ltl.sequence, !ltl.sequence
  call @Seq(%2) : (!ltl.sequence) -> ()
  call @Seq(%4) : (!ltl.sequence) -> ()
  call @Seq(%5) : (!ltl.sequence) -> ()

  // delay(concat(s0, s1), N, M) -> concat(delay(s0, N, M), s1)
  // CHECK-NEXT: [[TMP:%.+]] = ltl.delay %arg0, 2, 3 :
  // CHECK-NEXT: ltl.concat [[TMP]], %arg1 :
  // CHECK-NEXT: call
  %6 = ltl.concat %arg0, %arg1 : !ltl.sequence, !ltl.sequence
  %7 = ltl.delay %6, 2, 3 : !ltl.sequence
  call @Seq(%7) : (!ltl.sequence) -> ()
  return
}

// CHECK-LABEL: @RepeatFolds
func.func @RepeatFolds(%arg0: !ltl.sequence) {
  // repeat(s, 1, 0) -> s
  // CHECK-NEXT: call @Seq(%arg0)
  %0 = ltl.repeat %arg0, 1, 0: !ltl.sequence
  call @Seq(%0) : (!ltl.sequence) -> ()

  return
}

// CHECK-LABEL: @ClockingFolds
func.func @ClockingFolds(%arg0: !ltl.property) {
  // disable(p, false) -> p
  // CHECK-NEXT: call @Prop(%arg0)
  %false = hw.constant false
  %0 = ltl.disable %arg0 if %false : !ltl.property
  call @Prop(%0) : (!ltl.property) -> ()
  return
}
