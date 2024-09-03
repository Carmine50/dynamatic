set(LLVM_LINK_COMPONENTS
  Support
)

add_llvm_tool(esp-module-generator esp-module-generator.cpp)
llvm_update_compile_flags(esp-module-generator)
target_link_libraries(esp-module-generator
  PRIVATE
  DynamaticSupport
  DynamaticHandshake
)

