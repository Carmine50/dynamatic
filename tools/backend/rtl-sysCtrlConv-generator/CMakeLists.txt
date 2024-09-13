set(LLVM_LINK_COMPONENTS
  Support
)

add_llvm_tool(rtl-sysCtrlConv-generator rtl-sysCtrlConv-generator.cpp)
llvm_update_compile_flags(rtl-sysCtrlConv-generator)
target_link_libraries(rtl-sysCtrlConv-generator
  PRIVATE
  DynamaticSupport
  DynamaticHandshake
)

