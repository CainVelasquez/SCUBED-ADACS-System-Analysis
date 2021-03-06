%{
    Title: SCUBED ADACS Analysis
    Author: James E. Parkus, Amber Dubill
    Date: 10/29/2019
    Purpose: This script will calculate the characteristics of the SCUBED
    satellite's momentum wheels. The inputs are ____________, and the
    outputs are the required angular velocity of each wheels and the
    associated torques.

    Nomenclature:
    Earth Heliocentric Orbit - EHO

    Coordinate System:
        z - axis is the longitudinal axis of the CubeSat (axis that is always pointing towards the sun)
        y - axis is tangent to the orbital path
        x - axis completes the set

    Momentum Wheel Orientation:
        Wheel 1 -> principal axis is x-axis
        Wheel 2 -> principal axis is y-axis
        Wheel 3 -> principal axis is z-axis
%}

clc
clear
close all
format long

%% Memory Allocation
n = 10000;

%% Constants
T_EHO = 365.256363004*86400; % [s] - Orbital Period of EHO
orbit_altitude = 550; % [km]
earth_radius = 6378; % [km]
mu_earth = 398601.2; % [km^3/s^2] - Gravitational parameter for Earth
T_earth = 2*pi*(mu_earth)^(-1/2)*(orbit_altitude + earth_radius)^(3/2);

%% Simulink Simulation
% Initial Conditions
t = T_EHO; % simulation runtime
clock_decimation = 1;
vector_decimation = 1;

Mgx = 10^-11; % [Nm] - Solar pressure
Mgy = 10^-11; % [Nm] - Solar pressure
Mgz = 10^-11; % [Nm] - Solar pressure
M_SRP = 10^-4; % [Nm] - Solar Sailing Pressure

I = 2*10^-3; % [kg m^2] - Spin moment of inertia
J = 10^-3;
A = 0.032;
B = 0.021;
C = 0.046;

J_I = A + I + 2*J;
J_II = B + I + 2*J;
J_III = C + I + 2*J;

% Wheel Initial Angular Velocities
omega1_i = 0; % Initial conditions of wheel 1 at t = 0
omega2_i = 0; % Initial conditions of wheel 2 at t = 0
omega3_i = 0; % Initial conditions of wheel 3 at t = 0

% Body Angular Velocity
omega_x = 2*pi/T_EHO;
omega_y = 0;
omega_z = 0;
alpha_x = 0;
alpha_y = 0;
alpha_z = 0;

% Run Simulation
Simulation = sim('Momentum_Wheel_Model');

% Extract results
time = Simulation.omega_1.time;
omega_1 = Simulation.omega_1.signals.values;
omega_2 = Simulation.omega_2.signals.values;
omega_3 = Simulation.omega_3.signals.values;

% Analyse results
omega_magnitude = sqrt(omega_1.^2 + omega_2.^2 + omega_3.^2);

% Angular Momentum of Vehicle
% {Hv} = ([Ibody_G] + Sum([Ii_G]))*{omega} + sum([Ii_Gi]*{omega_rel}) + {0;0;M_SRP*time}

I_body = [A 0 0;0 B 0;0 0 C];
I_w1 = [I 0 0;0 J 0;0 0 J];
I_w2 = [J 0 0;0 I 0;0 0 J];
I_w3 = [J 0 0;0 0 J;0 0 I];
omega = [omega_x;omega_y;omega_z];

H = zeros([3 length(time)]);
for i = 1:1:length(time)
    omega_rel_1 = [omega_1(i,1);0           ;0           ];
    omega_rel_2 = [0           ;omega_2(i,1);0           ];
    omega_rel_3 = [0           ;0           ;omega_3(i,1)];
    
    H(1:3,i) = (I_body + I_w1*omega_rel_1 + I_w2*omega_rel_2 + I_w3*omega_rel_3)*omega + I_w1*omega_rel_1 + I_w2*omega_rel_2 + I_w3*omega_rel_3;
end

%% Plotting
rpm_conversion = 60/(2*pi);

fig1 = figure();
hold on
plot(time/86400,omega_1.*rpm_conversion);
plot(time/86400,omega_2.*rpm_conversion);
plot(time/86400,omega_3.*rpm_conversion);
plot(time/86400,omega_magnitude.*rpm_conversion,'--');
hold off
grid on
xlabel('Time [days]');
ylabel('Angular Velocity, \omega [RPM]');
legend('\omega_1','\omega_2', '\omega_3','\omega_{RMS}');
title('Momentum Wheel Angular Velocity of S-CUBED');
xlim([0 max(time/86400)]);

fig2 = figure();
hold on
plot(time/86400,H);
hold off
grid on
xlabel('Time [days]');
ylabel('Angular Momentum, H [Nms]');
legend('H_x','H_y', 'H_z');
title('Angular Momentum of S-CUBED');
xlim([0 max(time/86400)]);
