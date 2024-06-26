//===-- Passes.td - Verif pass definition file ----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the passes that work on the Verif dialect.
//
//===----------------------------------------------------------------------===//

#ifndef CIRCT_DIALECT_VERIF_PASSES_TD
#define CIRCT_DIALECT_VERIF_PASSES_TD

include "mlir/Pass/PassBase.td"

/**
 * Checks the validity of clocked assertions, assumptions, and cover ops.
 */
def VerifyClockedAssertLike : Pass<"verify-clocked-assert-like", "hw::HWModuleOp"> {
  let summary = "Check that clocked-assert-like are valid.";
  let description = [{
    Checks that every `clocked_assert`, `clocked_assume` or `clocked_cover` op does not contain 
    a nested `ltl.clock` or `ltl.disable` operation in its operand tree.
  }];
  let constructor = "circt::verif::createVerifyClockedAssertLikePass()";
}

#endif // CIRCT_DIALECT_VERIF_PASSES_TD
