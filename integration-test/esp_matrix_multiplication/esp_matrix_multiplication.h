#ifndef EXTERNAL_EXTERNAL_H
#define EXTERNAL_EXTERNAL_H

typedef int out_int_t; 
typedef int in_int_t;

typedef long out_long_t; 
typedef long in_long_t;

long __esp_stream(long fifo_in, int conf_info_op_mode, int conf_info_fpsa, int conf_info_mat_1_size);
int __esp_LoadReqESP(int iBurst, int conf_info_mat_1_size);
int __esp_StoreReqESP(int iBurst, int conf_info_mat_1_size, int conf_info_mat_out_size);
long load_ctrl(int out);
long store_ctrl(int out);
long out_word_V(long out);
long in1_word_V();

//long __fifo(long ins);
//long __decoder(long data_in);
//long __systolic_unit(int start, int tile_op_mode, int tile_fpsa_config, long data_in_1, long data_in_2);
//long __systolic_ctrl_unit(long data_in, int condition);


//int esp_matrix_multiplication(in_int_t conf_info_nbursts, in_int_t conf_info_mat_1_size, in_int_t conf_info_mat_out_size , in_int_t conf_info_fpsa, 
//                              in_int_t conf_info_op_mode, in_long_t fifo_in, out_long_t fifo_out, out_int_t load_ctrl, out_int_t store_ctrl);
void esp_matrix_multiplication(in_int_t conf_info_nbursts, in_int_t conf_info_mat_1_size, in_int_t conf_info_mat_out_size , in_int_t conf_info_fpsa, in_int_t conf_info_op_mode);



#endif // EXTERNAL_EXTERNAL_H


