set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
####################################################################################################################
#                                               CLOCK 100MHz                                                       #
####################################################################################################################
##Clock Signal
set_property -dict { PACKAGE_PIN "N14"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { clk100 }]     ;     
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100]
create_clock -add -name hdmi_clk -period 13.300 -waveform {0 5} [get_ports hdmi_rx_clk_p] 
##HDMI in 1080p or 720p or 1080p@50
#create_clock -add -name hdmi_clk -period 6.734 -waveform {0 5} [get_ports hdmi_rx_clk_p]  
#create_clock -add -name hdmi_clk -period 8.08080808081 -waveform {0 5} [get_ports hdmi_rx_clk_p] 

# ignore inter-clock path 
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -of_objects [get_pins i_hdmi_io/i_hdmi_input/hdmi_MMCME2_BASE_inst/CLKOUT0]]
set_false_path -through [get_ports led[*]]
set_false_path -through [get_ports newSW[*]]
set_false_path -from [get_clocks hdmi_clk] -to [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]]
set_false_path -from [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins i_hdmi_io/i_hdmi_input/hdmi_MMCME2_BASE_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins i_hdmi_io/i_hdmi_input/hdmi_MMCME2_BASE_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]]
set_false_path -from [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins i_hdmi_io/i_hdmi_input/hdmi_MMCME2_BASE_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins i_hdmi_io/i_hdmi_input/hdmi_MMCME2_BASE_inst/CLKOUT2]]
set_false_path -from [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT1]] 
set_false_path -to [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT1]]
# set CE false path
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch1/i_deser/ISERDESE2_slave/CE1] 
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch2/i_deser/ISERDESE2_slave/CE1] 
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch1/i_deser/ISERDESE2_master/CE1] 
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch0/i_deser/ISERDESE2_slave/CE1] 
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch0/i_deser/ISERDESE2_master/CE1] 
set_max_delay 26.0 -from [get_pins {i_hdmi_io/i_hdmi_input/CE_Delay/m_reg[1]/C}] -to [get_pins i_hdmi_io/i_hdmi_input/ch2/i_deser/ISERDESE2_master/CE1] 
####################################################################################################################
#                                               LEDs                                                               #
####################################################################################################################
set_property -dict { PACKAGE_PIN "K13"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[0] }];                      # IO_L21P_T3_DQS_15             Sch = led0
set_property -dict { PACKAGE_PIN "K12"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[1] }];                      # IO_L21N_T3_DQS_A18_15         Sch = led1
set_property -dict { PACKAGE_PIN "L14"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[2] }];                      # IO_L22P_T3_A17_15             Sch = led2
set_property -dict { PACKAGE_PIN "L13"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[3] }];                      # IO_L22N_T3_A16_15             Sch = led3
set_property -dict { PACKAGE_PIN "M15"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[4] }];                      # IO_L23P_T3_FOE_B_15           Sch = led4
set_property -dict { PACKAGE_PIN "M14"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[5] }];                      # IO_L23N_T3_FWE_B_15           Sch = led5
set_property -dict { PACKAGE_PIN "M12"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[6] }];                      # IO_L24P_T3_RS1_15             Sch = led6
set_property -dict { PACKAGE_PIN "P14"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[7] }];                      # IO_L24N_T3_RS0_15             Sch = led7



####################################################################################################################
#                                               HDMI Signals                                                       #
####################################################################################################################

##HDMI out
set_property -dict { PACKAGE_PIN "F3"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_clk_n}];  #BANKA 46
set_property -dict { PACKAGE_PIN "F4"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_clk_p}]; #BANKA 48
set_property -dict { PACKAGE_PIN "D5"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[0] }]; #BANKA 52
set_property -dict { PACKAGE_PIN "D6"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[0] }]; #BANKA 54 
set_property -dict { PACKAGE_PIN "B1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[1] }]; #BANKA 58
set_property -dict { PACKAGE_PIN "C1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[1] }];  #BANKA 60
set_property -dict { PACKAGE_PIN "A2"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[2] }];  #BANKA 64  
set_property -dict { PACKAGE_PIN "B2"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[2] }];  #BANKA 66

##HDMI in

# HDMI_In
set_property -dict { PACKAGE_PIN "B5"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_cec  }];    #BANKA 75    
set_property -dict { PACKAGE_PIN "E5"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_clk_n}];    #BANKA 45
set_property -dict { PACKAGE_PIN "F5"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_clk_p}];    #BANKA 47
set_property -dict { PACKAGE_PIN "B6"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_hpa  }];    #BANKA 77  
set_property -dict { PACKAGE_PIN "C3"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_scl  }];      #BANKA 71                          
set_property -dict { PACKAGE_PIN "C2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_sda  }];      #BANKA 69 
set_property -dict { PACKAGE_PIN "A3"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[0] }];    #BANKA 51
set_property -dict { PACKAGE_PIN "B4"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[0] }];    #BANKA 53
set_property -dict { PACKAGE_PIN "A4"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[1] }];    #BANKA 57
set_property -dict { PACKAGE_PIN "A5"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[1] }];    #BANKA 59
set_property -dict { PACKAGE_PIN "D1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[2] }];    #BANKA 63
set_property -dict { PACKAGE_PIN "E2"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[2] }];    #BANKA 65


#####################################################################################################################
##                                          Bank A for Camera 1                                                  #
#####################################################################################################################
## A17    trigger ready 
set_property -dict  { PACKAGE_PIN "H2"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C1_in[0]}];                   # IO_L1P_T0_AD0P_15             Sch = GPIO_20_P
## A23  trigger
set_property -dict  { PACKAGE_PIN "F2"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C1_out[0]}];                     # IO_L3P_T0_DQS_AD1P_15         Sch = GPIO_19_P
## A29  first frame
set_property -dict  { PACKAGE_PIN "G5"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C1_out[1]}];                      # IO_L20P_T3_A20_15             Sch = GPIO_18_P
## A35 hdmi switch
set_property -dict  { PACKAGE_PIN "G2"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C1_in[1]}];                      # IO_L19P_T3_A22_15             Sch = GPIO_17_P
#####################################################################################################################
##                                          Bank A for    Camera 2                                                  #
#####################################################################################################################
## A18    reserved 
#set_property -dict  { PACKAGE_PIN "K3"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C2_in[0]}];                      # IO_L2P_T0_16                  Sch = GPIO_40_P
## A24    trigger
set_property -dict  { PACKAGE_PIN "J3"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C2_out[0]}];                      # IO_L1P_T0_16                  Sch = GPIO_39_P
## A30    reserved  
set_property -dict  { PACKAGE_PIN "H5"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C2_out[1]}];                      # IO_L4P_T0_16                  Sch = GPIO_38_P  
## A36   reserved 
#set_property -dict  { PACKAGE_PIN "J5"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {C2_in[1]}];                      # IO_L6P_T0_16                  Sch = GPIO_37_P

#####################################################################################################################
##                                          Bank A for    newSW                                                #
#####################################################################################################################
## A5   Scan Orientation 
set_property -dict  { PACKAGE_PIN "M6"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {newSW[0]}];                      # IO_L2P_T0_16                  Sch = GPIO_40_P
## A6    Blue Enable
set_property -dict  { PACKAGE_PIN "N9"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {newSW[1]}];                      # IO_L1P_T0_16                  Sch = GPIO_39_P
## A11    Green Enable
set_property -dict  { PACKAGE_PIN "K1"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {newSW[2]}];                      # IO_L4P_T0_16                  Sch = GPIO_38_P  
## A12   Red Enable
set_property -dict  { PACKAGE_PIN "L3"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {newSW[3]}]; 

#####inter-clock false path######
#set_false_path -from [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins ref_clk_pll/inst/mmcm_adv_inst/CLKOUT2]]