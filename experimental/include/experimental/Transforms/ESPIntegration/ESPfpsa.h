//===- ESPfpsa.h - Integration of ESP FPSA in dynamatic -----*- C++ -*-===//
//
// Dynamatic is under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the ESP FPSA pass
//
//===----------------------------------------------------------------------===//

#ifndef EXPERIMENTAL_TRANSFORMS_ESP_FPSA_H
#define EXPERIMENTAL_TRANSFORMS_ESP_FPSA_H

#include "dynamatic/Support/DynamaticPass.h"
#include "dynamatic/Support/LLVM.h"

namespace dynamatic {
namespace experimental {
namespace espIntegration {

#define GEN_PASS_DECL_ESPFPSA
#define GEN_PASS_DEF_ESPFPSA
#include "experimental/Transforms/Passes.h.inc"

std::unique_ptr<dynamatic::DynamaticPass>
insertESPfpsa(std::string fpsaMode = "matMul", std::string arcPath = "");

} // namespace espIntegration
} // namespace experimental
} // namespace dynamatic

#endif // EXPERIMENTAL_TRANSFORMS_ESP_FPSA_H
