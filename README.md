# CAV
Security Simulation for CAV system

Instructions to Run:
1) Use Erlang OTP
2) Input erl to open erlang shell
3) c(cav).
4) cav:simulator(#of_sensor_interactions, #of_v2x_interactions) //models core CAV functionality
5) cav:jamsimulator(#of_sensor_interactions, #of_v2x_interactions) //models CAV functionality under jamming and DoS attacks
5) cav:spoofimulator(#of_sensor_interactions, #of_v2x_interactions) //models CAV functionality under jamming and DoS attacks
