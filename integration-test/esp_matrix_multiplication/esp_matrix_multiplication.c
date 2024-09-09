#include "esp_matrix_multiplication.h"
#include "dynamatic/Integration.h"


//int esp_matrix_multiplication(in_int_t conf_info_nbursts, in_int_t conf_info_mat_1_size, in_int_t conf_info_mat_out_size , in_int_t conf_info_fpsa, 
//                              in_int_t conf_info_op_mode, in_long_t fifo_in, out_long_t fifo_out, out_int_t load_ctrl, out_int_t store_ctrl){
void esp_matrix_multiplication(in_int_t conf_info_nbursts, in_int_t conf_info_mat_1_size, in_int_t conf_info_mat_out_size , in_int_t conf_info_fpsa, in_int_t conf_info_op_mode){


  int iBurst, iPacket;
  long result_fifo_out;
  for (iBurst = 0; iBurst < conf_info_nbursts; iBurst++)
  {
    load_ctrl( __esp_LoadReqESP(iBurst, conf_info_mat_1_size) );
    //long value = __fifo(fifo_in);
    //value =
    for ( iPacket = 0; iPacket < conf_info_mat_1_size ; iPacket++ ){
      long fifo_in =  in1_word_V();
      result_fifo_out =  __esp_fpsa(fifo_in, conf_info_op_mode, conf_info_fpsa, conf_info_mat_1_size);
      out_word_V( result_fifo_out );
    }


    store_ctrl( __esp_StoreReqESP(iBurst, conf_info_mat_1_size, conf_info_mat_out_size) );
  }

  //long result_fifo_out =  __esp_stream(fifo_in, conf_info_op_mode, conf_info_fpsa);
  //return external_function( result_fifo_out );
  //return 1;
}

int main(void) {
  int a = 10;
  int b = 8;
  int c = 13;
  int d = 13;
  int e = 13;
  long f = 13;

  CALL_KERNEL(esp_matrix_multiplication, a, b, c, d, e );
  return 0;
}


