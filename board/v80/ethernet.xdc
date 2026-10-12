# Uncomment below qsfp pins as design requires
set_property -dict { PACKAGE_PIN AR51                                                 } [get_ports "qsfp0_322mhz_clk_p"]    ;# Bank 209 " GTM_REFCLKP0_209
create_clock -period 3.103 -name qsfp0_refclk [get_ports qsfp0_322mhz_clk_p]
set_property -dict { PACKAGE_PIN AE67                                                 } [get_ports "qsfp0_4x_grx_p[0]"]     ;# Bank 209 " GTM_RXP0_209    
set_property -dict { PACKAGE_PIN AE64                                                 } [get_ports "qsfp0_4x_grx_p[1]"]     ;# Bank 209 " GTM_RXP1_209    
set_property -dict { PACKAGE_PIN AC67                                                 } [get_ports "qsfp0_4x_grx_p[2]"]     ;# Bank 209 " GTM_RXP2_209    
set_property -dict { PACKAGE_PIN AC64                                                 } [get_ports "qsfp0_4x_grx_p[3]"]     ;# Bank 209 " GTM_RXP3_209    
                                                                                                                                                          
set_property -dict { PACKAGE_PIN AG61                                                 } [get_ports "qsfp0_4x_gtx_p[0]"]     ;# Bank 209 " GTM_TXP0_209    
set_property -dict { PACKAGE_PIN AG58                                                 } [get_ports "qsfp0_4x_gtx_p[1]"]     ;# Bank 209 " GTM_TXP1_209    
set_property -dict { PACKAGE_PIN AE61                                                 } [get_ports "qsfp0_4x_gtx_p[2]"]     ;# Bank 209 " GTM_TXP2_209    
set_property -dict { PACKAGE_PIN AE58                                                 } [get_ports "qsfp0_4x_gtx_p[3]"]     ;# Bank 209 " GTM_TXP3_209
# 
# set_property -dict { PACKAGE_PIN AA67                                                 } [get_ports "qsfp1_4x_grx_p[0]"]     ;# Bank 210 " GTM_RXP0_210
# set_property -dict { PACKAGE_PIN AA64                                                 } [get_ports "qsfp1_4x_grx_p[1]"]     ;# Bank 210 " GTM_RXP1_210
# set_property -dict { PACKAGE_PIN W67                                                  } [get_ports "qsfp1_4x_grx_p[2]"]     ;# Bank 210 " GTM_RXP2_210
# set_property -dict { PACKAGE_PIN W64                                                  } [get_ports "qsfp1_4x_grx_p[3]"]     ;# Bank 210 " GTM_RXP3_210
#                                                                                                                              
# set_property -dict { PACKAGE_PIN AC61                                                 } [get_ports "qsfp1_4x_gtx_p[0]"]     ;# Bank 210 " GTM_TXP0_210
# set_property -dict { PACKAGE_PIN AC58                                                 } [get_ports "qsfp1_4x_gtx_p[1]"]     ;# Bank 210 " GTM_TXP1_210
# set_property -dict { PACKAGE_PIN AA61                                                 } [get_ports "qsfp1_4x_gtx_p[2]"]     ;# Bank 210 " GTM_TXP2_210
# set_property -dict { PACKAGE_PIN AA58                                                 } [get_ports "qsfp1_4x_gtx_p[3]"]     ;# Bank 210 " GTM_TXP3_210
# 
# set_property -dict { PACKAGE_PIN AL17                                                 } [get_ports "qsfp2_322mhz_clk_p"]    ;# Bank 111 " GTM_REFCLKP0_111
#                          
# set_property -dict { PACKAGE_PIN U3                                                   } [get_ports "qsfp2_4x_grx_p[0]"]     ;# Bank 112 " GTM_RXP0_112
# set_property -dict { PACKAGE_PIN U6                                                   } [get_ports "qsfp2_4x_grx_p[1]"]     ;# Bank 112 " GTM_RXP1_112
# set_property -dict { PACKAGE_PIN R3                                                   } [get_ports "qsfp2_4x_grx_p[2]"]     ;# Bank 112 " GTM_RXP2_112
# set_property -dict { PACKAGE_PIN R6                                                   } [get_ports "qsfp2_4x_grx_p[3]"]     ;# Bank 112 " GTM_RXP3_112
#                                                                                                                              
# set_property -dict { PACKAGE_PIN U9                                                   } [get_ports "qsfp2_4x_gtx_p[0]"]     ;# Bank 112 " GTM_TXP0_112
# set_property -dict { PACKAGE_PIN U12                                                  } [get_ports "qsfp2_4x_gtx_p[1]"]     ;# Bank 112 " GTM_TXP1_112
# set_property -dict { PACKAGE_PIN R9                                                   } [get_ports "qsfp2_4x_gtx_p[2]"]     ;# Bank 112 " GTM_TXP2_112
# set_property -dict { PACKAGE_PIN R12                                                  } [get_ports "qsfp2_4x_gtx_p[3]"]     ;# Bank 112 " GTM_TXP3_112
# 
# set_property -dict { PACKAGE_PIN AA3                                                  } [get_ports "qsfp3_4x_grx_p[0]"]     ;# Bank 111 " GTM_RXP0_111
# set_property -dict { PACKAGE_PIN AA6                                                  } [get_ports "qsfp3_4x_grx_p[1]"]     ;# Bank 111 " GTM_RXP1_111
# set_property -dict { PACKAGE_PIN W3                                                   } [get_ports "qsfp3_4x_grx_p[2]"]     ;# Bank 111 " GTM_RXP2_111
# set_property -dict { PACKAGE_PIN W6                                                   } [get_ports "qsfp3_4x_grx_p[3]"]     ;# Bank 111 " GTM_RXP3_111
#                                                                                                                              
# set_property -dict { PACKAGE_PIN AA9                                                  } [get_ports "qsfp3_4x_gtx_p[0]"]     ;# Bank 111 " GTM_TXP0_111
# set_property -dict { PACKAGE_PIN AA12                                                 } [get_ports "qsfp3_4x_gtx_p[1]"]     ;# Bank 111 " GTM_TXP1_111
# set_property -dict { PACKAGE_PIN W9                                                   } [get_ports "qsfp3_4x_gtx_p[2]"]     ;# Bank 111 " GTM_TXP2_111
# set_property -dict { PACKAGE_PIN W12                                                  } [get_ports "qsfp3_4x_gtx_p[3]"]     ;# Bank 111 " GTM_TXP3_111 
