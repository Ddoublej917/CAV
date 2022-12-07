-module(cav).
-import(string,[concat/2]).

-compile([export_all]).

%Environmental Sensing Subsystem
    %GPS
    %Radar
    %Lidar
    %Camera

ess(AMS, Authinfo, States, N) ->
    if N > 0->
        %receive sensor data from environment
        io:fwrite("Receiving Sensor Data~n"),
        RadarState = lists:nth(1, States),
        RadarAuth = lists:nth(1, Authinfo),
        LidarState = lists:nth(2, States),
        LidarAuth = lists:nth(2, Authinfo),
        GPSState = lists:nth(3, States),
        GPSAuth = lists:nth(3, Authinfo),
        CameraState = lists:nth(4, States),
        CameraAuth = lists:nth(4, Authinfo),
        %randomly generate road hazards
        GPSdata = "True Data",
        HazardRNG = rand:uniform(),
        if HazardRNG < 0.3 ->
            Direction = rand:uniform(),
            Source = rand:uniform(),
            if Direction < 0.25 ->
                if Source < 0.33 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Potential Hazard",
                    Lidardata = "Road Hazard North";
                Source < 0.66 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Road Hazard North",
                    Lidardata = "Potential Hazard";
                true ->
                    Cameradata = "Road Hazard North",
                    Radardata = "Potential Hazard",
                    Lidardata = "Potential Hazard"
                end;
            Direction < 0.5 ->
                if Source < 0.33 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Potential Hazard",
                    Lidardata = "Road Hazard East";
                Source < 0.66 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Road Hazard East",
                    Lidardata = "Potential Hazard";
                true ->
                    Cameradata = "Road Hazard East",
                    Radardata = "Potential Hazard",
                    Lidardata = "Potential Hazard"
                end;
            Direction < 0.75 ->
                if Source < 0.33 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Potential Hazard",
                    Lidardata = "Road Hazard South";
                Source < 0.66 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Road Hazard South",
                    Lidardata = "Potential Hazard";
                true ->
                    Cameradata = "Road Hazard South",
                    Radardata = "Potential Hazard",
                    Lidardata = "Potential Hazard"
                end;
            true ->
                if Source < 0.33 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Potential Hazard",
                    Lidardata = "Road Hazard West";
                Source < 0.66 ->
                    Cameradata = "Potential Hazard",
                    Radardata = "Road Hazard West",
                    Lidardata = "Potential Hazard";
                true ->
                    Cameradata = "Road Hazard West",
                    Radardata = "Potential Hazard",
                    Lidardata = "Potential Hazard"
                end
            end;

        true ->
            Radardata = "All Clear",
            Lidardata = "All Clear",
            GPSdata = "True Data",
            Cameradata = "All Clear"
        end,
        %send sensor data to AMS
        if
            RadarState == "Operational"->
                AMS ! {"Radar", Radardata, RadarAuth};
            RadarState == "Reboot"->
                io:fwrite("Radar Enabled~n"),
                AMS ! {"Authenticate", RadarAuth},
                AMS ! {"Radar", "All Clear", RadarAuth};
            true ->
                io:fwrite("Radar Disabled~n"),
                AMS ! {"Revoke", RadarAuth}
        end,
        if
            LidarState == "Operational"->
                AMS ! {"Lidar", Lidardata, LidarAuth};
            RadarState == "Reboot"->
                io:fwrite("Radar Enabled~n"),
                AMS ! {"Authenticate", RadarAuth},
                AMS ! {"Radar", "All Clear", RadarAuth};
            true ->
                io:fwrite("Lidar Disabled~n"),
                AMS ! {"Revoke", LidarAuth}
        end,
        if
            GPSState == "Operational"->
                AMS ! {"GPS", GPSdata, GPSAuth};
            RadarState == "Reboot"->
                io:fwrite("Radar Enabled~n"),
                AMS ! {"Authenticate", RadarAuth},
                AMS ! {"Radar", "All Clear", RadarAuth};
            true ->
                io:fwrite("GPS Disabled~n"),
                AMS ! {"Revoke", GPSAuth}
        end,
        if
            CameraState == "Operational"->
                AMS ! {"Camera", Cameradata, CameraAuth};
            CameraState == "Reboot"->
                io:fwrite("Camera Enabled~n"),
                AMS ! {"Authenticate", CameraAuth},
                AMS ! {"Radar", "All Clear", CameraAuth};
            true ->
                io:fwrite("Camera Disabled~n"),
                AMS ! {"Revoke", CameraAuth}
        end,
        ess(AMS, Authinfo, States, N - 1);
    true ->
        io:fwrite("All sensor Data Sent~n"),
        AMS ! {"Park Car"}
    end.



%Communication Subsystem
    %V2V - vehicle to vehicle
    %V2I - vehicle to infrastructure
    %V2X - vehicle to everything

v2x(AMS)->
    receive
        {Type, Message, Authinfo}->
            %encryption of v2x messages
            Key = <<1:256>>,
            IV = <<0:128>>,
            Text = Message,
            AAD = <<>>,
            {CipherText, Tag} = crypto:crypto_one_time_aead(aes_256_gcm, Key, IV, Text, AAD, true),
            Encrypted = {Key, IV, CipherText, AAD, Tag},
            if
                Type == "Vehicle"->
                    AMS ! {Type, Encrypted, Authinfo},
                    io:fwrite("Communication with Vehicle Established~n");
                Type == "Infrastructure"->
                    AMS ! {Type, Encrypted, Authinfo},
                    io:fwrite("Communication with Infrastructure Established~n");
                Type == "Cloud"->
                    AMS ! {Type, Encrypted, Authinfo},
                    io:fwrite("Communication with Cloud Established~n");
                true->
                    io:fwrite("Communication with Unknown Entity Denied~n")
            end,
            v2x(AMS)
    end.
%Autonomous Motion Subsystem
    %main server
    %accept inputs -> process inputs -> issue command

% Trusted Systems is a dict of <Authinfo,PID>
ams(ECU, TrustedSystems) ->
    receive
        {Command} ->
                ECU ! {Command};   
        {Command, Authinfo} ->
            case Command of
                "Authenticate" ->
                    % add auth data to database database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            UpdatedTrustedSystems = dict:append(Authinfo, [], TrustedSystems),
                            ams(ECU, UpdatedTrustedSystems);
                        true ->
                            io:fwrite("System Already Authorized~n"),
                            ams(ECU, TrustedSystems)
                    end;
                "Revoke" ->
                    % remove auth data from database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            io:fwrite("System Already Authorized~n"),
                            ams(ECU, TrustedSystems);
                        true ->
                            UpdatedTrustedSystems = dict:erase(Authinfo, TrustedSystems),
                            ams(ECU, UpdatedTrustedSystems)
                    end
                end;
        {Source, Data, Authinfo} ->
            case Source of
                "Radar" ->
                    io:format("Radar Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            io:format("Untrusted Radar Data Received~n");
                        true ->
                            %process data
                            if 
                                Data == "All Clear" ->
                                    ECU ! {"Proceed On Route"};
                                Data == "Potential Hazard" ->
                                    ECU ! {"Other Sensor Detected Hazard"};
                                Data == "Road Hazard North"->
                                    ECU ! {"Road Hazard Detected Ahead By Radar, Averting"};
                                Data == "Road Hazard East"->
                                    ECU ! {"Road Hazard Detected East By Radar, Averting"};
                                Data == "Road Hazard West"->
                                    ECU ! {"Road Hazard Detected West By Radar, Averting"};
                                Data == "Road Hazard South"->
                                    ECU ! {"Road Hazard Detected Behind By Radar, Averting"};
                                Data == "False Data"->
                                    ECU ! {"False Radar Data Received"},
                                    ECU ! {"CRASH"};
                                Data == "Hidden Object"->
                                    %send message to ESS to revoke sensor auth
                                    self() ! {"Revoke", Authinfo},
                                    ECU ! {"Hidden Object Attack"},
                                    ECU ! {"Enable Backup Sensors"};
                                true ->
                                    io:format("Invalid Radar Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                    
                "Lidar" ->
                    io:format("Lidar Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            io:format("Untrusted Lidar Data Received~n");
                        true ->
                            if 
                                Data == "Blind Data" ->
                                    %send message to ESS to revoke sensor auth
                                    self() ! {"Revoke", Authinfo},
                                    ECU ! {"Enable Backup Sensors"};
                                Data == "Potential Hazard" ->
                                    ECU ! {"Other Sensor Detected Hazard"};
                                Data == "False Data" ->
                                    ECU ! {"False Lidar Data Received"},
                                    ECU ! {"CRASH"};
                                Data == "All Clear" ->
                                    ECU ! {"Proceed On Route"};
                                Data == "Road Hazard North"->
                                    ECU ! {"Road Hazard Detected Ahead By Lidar, Averting"};
                                Data == "Road Hazard East"->
                                    ECU ! {"Road Hazard Detected East By Lidar, Averting"};
                                Data == "Road Hazard West"->
                                    ECU ! {"Road Hazard Detected West By Lidar, Averting"};
                                Data == "Road Hazard South"->
                                    ECU ! {"Road Hazard Detected Behind By Lidar, Averting"};
                                Data == "Fake Data"->
                                    ECU ! {"Crash Due to False Lidar Data"};
                                true ->
                                    io:format("Invalid Radar Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                "GPS" ->
                    io:format("GPS Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            io:format("Untrusted GPS Data Received~n");
                        true ->
                            %process data
                            if 
                                Data == "Spoofed Data" ->
                                    ECU ! {"Spoofed GPS Data Received"},
                                    ECU ! {"CRASH"};
                                Data == "True Data"->
                                    ECU ! {"Valid GPS Data Received for Position and Route"};
                                Data == "Jamming"->
                                    ECU ! {"GPS Receivers Jammed"},
                                    %send message to ESS to revoke sensor auth
                                    self() ! {"Revoke", Authinfo},
                                    ECU ! {"Enable Backup Sensors"};
                                true ->
                                    io:format("Invalid GPS Data Received~n")
                            end
                            %send command to vehicle
                    end,
                    ams(ECU, TrustedSystems);
                "Camera" ->
                    io:format("Camera Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    if
                        Result == error ->
                            io:format("Untrusted Camera Data Received~n");
                        true ->
                            if 
                                Data == "Blind Data" ->
                                    %send message to ESS to revoke sensor auth
                                    self() ! {"Revoke", Authinfo},
                                    ECU ! {"Enable Backup Sensors"};
                                Data == "Potential Hazard" ->
                                    ECU ! {"Other Sensor Detected Hazard"};
                                Data == "False Data" ->
                                    ECU ! {"False Camera Data Received"},
                                    ECU ! {"CRASH"};
                                Data == "All Clear" ->
                                    ECU ! {"Proceed On Route"};
                                Data == "Road Hazard North"->
                                    ECU ! {"Road Hazard Detected Ahead By Camera, Averting"};
                                Data == "Road Hazard East"->
                                    ECU ! {"Road Hazard Detected East By Camera, Averting"};
                                Data == "Road Hazard West"->
                                    ECU ! {"Road Hazard Detected West By Camera, Averting"};
                                Data == "Road Hazard South"->
                                    ECU ! {"Road Hazard Detected Behind By Camera, Averting"};
                                true ->
                                    io:format("Invalid Radar Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                "Vehicle" ->
                    io:format("Vehicle Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    {Key, IV, CipherText, AAD, Tag} = Data,
                    Data1 = crypto:crypto_one_time_aead(aes_256_gcm, Key, IV, CipherText, AAD, Tag, false),
                    io:format("Decrypted Message: ~p~n", [Data1]),
                    if
                        Result == error ->
                            io:format("Untrusted Vehicle Data Received~n");
                        true ->
                            %process data
                            if 
                                Data1 == <<"DoS Attack">> ->
                                    ECU ! {"DoS Attack Underway"},
                                    self() ! {"Revoke", Authinfo},
                                    io:format("Message limit reached, cutting off communication~n");
                                Data1 == <<"True Sensor Data">>->
                                    ECU ! {"Communication With Verified Vehicle Successful"};
                                Data1 == <<"False Sensor Data">>->
                                    ECU ! {"False Data from Vehicle Received"},
                                    ECU ! {"CRASH"};
                                true ->
                                    io:format("Invalid Vehicle Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                "Infrastructure" ->
                    io:format("Infrastructure Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    {Key, IV, CipherText, AAD, Tag} = Data,
                    Data1 = crypto:crypto_one_time_aead(aes_256_gcm, Key, IV, CipherText, AAD, Tag, false),
                    io:format("Decrypted Message: ~p~n", [Data1]),
                    if
                        Result == error ->
                            io:format("Untrusted Infrastructure Data Received~n");
                        true ->
                            %process data
                            if 
                                Data1 == <<"True Sensor Data">>->
                                    ECU ! {"Communication With Verified Infrastructure Successful"};
                                Data1 == <<"DoS Attack">> ->
                                    ECU ! {"DoS Attack Underway"},
                                    self() ! {"Revoke", Authinfo},
                                    io:format("Message limit reached, cutting off communication~n");
                                Data1 == <<"False Sensor Data">>->
                                    ECU ! {"False Data from Infrastructure Received"},
                                    ECU ! {"CRASH"};
                                true ->
                                    io:format("Invalid Infrastructure Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                "Cloud" ->
                    io:format("Cloud Data Received From: ~p~n", [Authinfo]),
                    %authenticate source of info in trusted database
                    Result = dict:find(Authinfo, TrustedSystems),
                    {Key, IV, CipherText, AAD, Tag} = Data,
                    Data1 = crypto:crypto_one_time_aead(aes_256_gcm, Key, IV, CipherText, AAD, Tag, false),
                    io:format("Decrypted Message: ~p~n", [Data1]),
                    if
                        Result == error ->
                            io:format("Untrusted Infrastructure Data Received~n");
                        true ->
                            %process data
                            if 
                                Data1 == <<"True Cloud Data">>->
                                    ECU ! {"Download From Verified Manufacturer Cloud Successful"};
                                Data1 == <<"False Cloud Data">>->
                                    ECU ! {"False Data from Cloud Received"};
                                true ->
                                    io:format("Invalid Cloud Data Received~n")
                            end
                    end,
                    ams(ECU, TrustedSystems);
                "Unverified" ->
                    io:format("Data Received from Unverified Source~n")
            end
        end.

%TODO: Make ECU
ecu() ->
    receive
        {Command} ->
            if Command == "Park Car" ->
                io:format("Parking Car~n"),
                io:format("Arrived Safely at Destination~n");
            Command == "CRASH" ->
                io:format("CAV has crashed due to a cyberattack~n");
            Command == "Switch to Manual Drving" ->
                io:format("ESS Disabled, Switching to Manual Operation of Vehicle~n");
            Command == "Enable Backup Sensors" ->
                io:format("Primary Sensor Blinded, Relying on Redundant Sensors~n"),
                ecu();
            true->
                io:format("~p~n", [Command]),
                ecu()
            end
    end.

interactions(N, V2X) ->
    if N > 0 ->
        IntRNG = rand:uniform(),
        if IntRNG < 0.4 ->
            V2X ! {"Vehicle", "True Sensor Data", "Valid VehicleID"};
        IntRNG < 0.6 ->
            V2X ! {"Infrastructure", "True Sensor Data", "Valid InfraID"};
        IntRNG < 0.8 ->
            V2X ! {"Cloud", "True Cloud Data", "Valid CloudID"};
        true ->
            V2X ! {"Unverified", "Spoofed Sensor Data", "Fake Auth"}
        end,
        interactions(N - 1, V2X);
    true ->
        ok
    end.
%Simulator with No Cyber Attacks
simulator(Miles, Interactions) ->
    ECU = spawn(?MODULE, ecu, []),
    AMS = spawn(?MODULE, ams, [ECU, dict:new()]),
    V2X = spawn(?MODULE, v2x, [AMS]),
    States = ["Operational", "Operational", "Operational", "Operational"],
    Authinfo = ["Valid RadarID", "Valid LidarID", "Valid GPSID", "Valid CameraID"],
    AMS ! {"Authenticate", "Valid RadarID"},
    AMS ! {"Authenticate", "Valid LidarID"},
    AMS ! {"Authenticate", "Valid GPSID"},
    AMS ! {"Authenticate", "Valid CameraID"},
    AMS ! {"Authenticate", "Valid VehicleID"},
    AMS ! {"Authenticate", "Valid InfraID"},
    AMS ! {"Authenticate", "Valid CloudID"},
    spawn(?MODULE, ess, [AMS, Authinfo, States, Miles]),
    interactions(Interactions, V2X).

%Jamming Cyber Attack Simulator
jamsimulator(Miles, Interactions) ->
    ECU = spawn(?MODULE, ecu, []),
    AMS = spawn(?MODULE, ams, [ECU, dict:new()]),
    V2X = spawn(?MODULE, v2x, [AMS]),
    States = ["Operational", "Operational", "Operational", "Operational"],
    Authinfo = ["Valid RadarID", "Valid LidarID", "Valid GPSID", "Valid CameraID"],
    AMS ! {"Authenticate", "Valid RadarID"},
    AMS ! {"Authenticate", "Valid LidarID"},
    AMS ! {"Authenticate", "Valid GPSID"},
    AMS ! {"Authenticate", "Valid CameraID"},
    AMS ! {"Authenticate", "Valid VehicleID"},
    AMS ! {"Authenticate", "Valid InfraID"},
    AMS ! {"Authenticate", "Valid CloudID"},
    spawn(?MODULE, ess, [AMS, Authinfo, States, Miles]),
    interactions(Interactions, V2X),
    %Atempted Sensor Jamming and Blinding Cyberattacks after MITM Attack
    io:format("Launching GPS Jamming Attack~n"),
    AMS ! {"GPS", "Jamming", "Valid GPSID"},
    io:format("Launching Radar Hidden Object Attack~n"),
    AMS ! {"Radar", "Hidden Object", "Valid RadarID"},
    io:format("Launching Lidar Blinding Attack~n"),
    AMS ! {"Lidar", "Blind Data", "Valid LidarID"},
    io:format("Launching Camera Blinding Attack~n"),
    AMS ! {"Camera", "Blind Data", "Valid CameraID"},
    %Atempted Communication Dos Cyberattacks
    io:format("Launching V2V DoS Attack~n"),
    V2X ! {"Vehicle", "DoS Attack", "Valid VehicleID"},
    io:format("Launching V2I DoS Attack~n"),
    V2X ! {"Infrastructure", "DoS Attack", "Valid InfraID"}.

%Spoofing Cyber Attack Simulator
spoofsimulator(Miles, Interactions) ->
    ECU = spawn(?MODULE, ecu, []),
    AMS = spawn(?MODULE, ams, [ECU, dict:new()]),
    V2X = spawn(?MODULE, v2x, [AMS]),
    States = ["Operational", "Operational", "Operational", "Operational"],
    Authinfo = ["Valid RadarID", "Valid LidarID", "Valid GPSID", "Valid CameraID"],
    AMS ! {"Authenticate", "Valid RadarID"},
    AMS ! {"Authenticate", "Valid LidarID"},
    AMS ! {"Authenticate", "Valid GPSID"},
    AMS ! {"Authenticate", "Valid CameraID"},
    AMS ! {"Authenticate", "Valid VehicleID"},
    AMS ! {"Authenticate", "Valid InfraID"},
    AMS ! {"Authenticate", "Valid CloudID"},
    spawn(?MODULE, ess, [AMS, Authinfo, States, Miles]),
    interactions(Interactions, V2X),
    %Atempted Sensor Cyberattacks
    AMS ! {"GPS", "Spoofed Data", "FakeID"},
    AMS ! {"Radar", "False Data", "FakeID"},
    AMS ! {"Lidar", "False Data", "FakeID"},
    AMS ! {"Camera", "False Data", "FakeID"},
    %Atempted Communication Cyberattacks
    V2X ! {"Vehicle", "False Sensor Data", "FakeID"},
    V2X ! {"Infrastructure", "False Sensor Data", "FakeID"},
    V2X ! {"Cloud", "Fake Cloud Data", "FakeID"},
    V2X ! {"Unverified", "False Data", "FakeID"}.
