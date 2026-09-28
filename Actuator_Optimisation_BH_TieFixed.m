clc
clear
close all

%% =========================================================
% ELECTROMAGNETIC ACTUATOR
% AUTOMATED ITERATION AND OPTIMISATION
%
% Design variables:
%   1. Number of laminations: 1 to 36
%   2. Number of coil turns: 1500 to 3000
%
% B-H curve:
%   H = (142.248*B)/(1.626-B)
%
% The program:
%   1. Calculates the four group designs
%   2. Performs the magnetic B-H iteration
%   3. Calculates reluctance, dR/dx, force and F/W
%   4. Searches the complete design space
%   5. Reports ALL tied optimum designs
% =========================================================


%% 1. FIXED INPUTS

V = 24;                         % Supply voltage [V]
D = 0.32e-3;                    % Wire diameter [m]
rhoCu = 1.73e-8;                % Copper resistivity [ohm.m]
Pbobbin = 84e-3;                % Bobbin perimeter [m]
mu0 = 4*pi*1e-7;                % Permeability of free space
lcore = 198e-3;                 % Magnetic path length [m]
tlam = 0.5e-3;                  % Lamination thickness [m]
rhoCore = 0.145e6;              % Core density [kg/m^3]


%% 2. CORE GEOMETRY

AT = (54e-3)*(45e-3);
Aremoved = 2*(27e-3)*(9e-3);
Alam = AT - Aremoved;


%% 3. AIR GAPS

lgt_old = 2.0e-3;
lgm_old = 1.0e-3;

lgt_new = 2.1e-3;
lgm_new = 1.05e-3;


%% 4. B-H CURVE

B_table = [0.00 0.95 1.20 1.30 1.37 1.42 1.45 1.47 1.48 1.49 1.50];
H_table = [0 200 400 600 800 1000 1200 1400 1600 1800 2000];


%% 5. OPTIMISATION RANGES

laminationRange = 1:36;
turnRange = 1500:50:3000;


%% =========================================================
% 6. FOUR GROUP DESIGNS
% =========================================================

manualLaminations = [36 18 18 36];
manualTurns = [3000 1500 3000 1500];

manualNames = {'Sozi','Ulu','Sph Mphandla','Wandile'};

fprintf('\n')
fprintf('============================================\n')
fprintf('FOUR MANUAL DESIGN ITERATIONS\n')
fprintf('============================================\n')

for k = 1:4

    nlam = manualLaminations(k);
    N = manualTurns(k);

    result = calculateDesign( ...
        nlam,N,V,D,rhoCu,Pbobbin,mu0,lcore, ...
        tlam,rhoCore,Alam,lgt_old,lgm_old, ...
        lgt_new,lgm_new);

    fprintf('\n%s\n',manualNames{k})
    fprintf('Laminations       = %d\n',nlam)
    fprintf('Turns             = %d\n',N)
    fprintf('Resistance        = %.4f ohm\n',result.Rcoil)
    fprintf('Current           = %.4f A\n',result.I)
    fprintf('MMF               = %.2f At\n',result.MMF)
    fprintf('B at 2.0 mm       = %.4f T\n',result.B_old)
    fprintf('B at 2.1 mm       = %.4f T\n',result.B_new)
    fprintf('R at 2.0 mm       = %.4e At/Wb\n',result.R_old)
    fprintf('R at 2.1 mm       = %.4e At/Wb\n',result.R_new)
    fprintf('dR/dx             = %.4e At/Wb/m\n',result.dRdx)
    fprintf('Force             = %.4f N\n',result.Force)
    fprintf('Mass              = %.4f kg\n',result.mass)
    fprintf('Weight            = %.4f N\n',result.weight)
    fprintf('Force/Weight      = %.6f\n',result.FWratio)

end


%% =========================================================
% 7. AUTOMATED OPTIMISATION
% =========================================================

results = [];

for a = 1:length(laminationRange)

    nlam = laminationRange(a);

    for b = 1:length(turnRange)

        N = turnRange(b);

        result = calculateDesign( ...
            nlam,N,V,D,rhoCu,Pbobbin,mu0,lcore, ...
            tlam,rhoCore,Alam,lgt_old,lgm_old, ...
            lgt_new,lgm_new);

        results = [results;
            nlam, ...
            N, ...
            result.Rcoil, ...
            result.I, ...
            result.MMF, ...
            result.B_old, ...
            result.B_new, ...
            result.R_old, ...
            result.R_new, ...
            result.dRdx, ...
            result.Force, ...
            result.mass, ...
            result.weight, ...
            result.FWratio];

    end

end


%% =========================================================
% 8. RESULTS TABLE
% =========================================================

Results = array2table(results);

Results.Properties.VariableNames = { ...
    'Laminations', ...
    'Turns', ...
    'Resistance', ...
    'Current', ...
    'MMF', ...
    'B_old', ...
    'B_new', ...
    'R_old', ...
    'R_new', ...
    'dRdx', ...
    'Force', ...
    'Mass', ...
    'Weight', ...
    'ForceWeightRatio'};


%% =========================================================
% 9. FIND ALL OPTIMUM DESIGNS
% =========================================================
%
% IMPORTANT:
% If several designs have exactly the same F/W ratio,
% MATLAB should NOT report an arbitrary turn value as
% the unique optimum.
%
% All tied maximum designs are displayed.
% =========================================================

bestRatio = max(Results.ForceWeightRatio);

tieTolerance = 1e-6;

bestRows = Results( ...
    abs(Results.ForceWeightRatio - bestRatio) ...
    <= tieTolerance, :);


fprintf('\n')
fprintf('============================================\n')
fprintf('OPTIMISATION RESULT\n')
fprintf('============================================\n')

fprintf('Maximum Force/Weight Ratio = %.6f\n',bestRatio)

fprintf('\nAll designs achieving the maximum:\n\n')

disp(bestRows(:, ...
    {'Laminations','Turns','Force','Mass','Weight','ForceWeightRatio'}))


%% =========================================================
% 10. APPLY A TIE-BREAKING RULE
% =========================================================
%
% If several designs have the same maximum F/W ratio,
% select the one with the FEWEST turns.
%
% This avoids MATLAB selecting an arbitrary tied row.
% =========================================================

minimumTurns = min(bestRows.Turns);

finalCandidates = bestRows( ...
    bestRows.Turns == minimumTurns, :);

% If there is still more than one candidate, choose the
% one with the largest force.

[~,idx] = max(abs(finalCandidates.Force));

Best = finalCandidates(idx,:);


fprintf('\n')
fprintf('============================================\n')
fprintf('SELECTED OPTIMUM DESIGN\n')
fprintf('============================================\n')

fprintf('Number of laminations = %d\n',Best.Laminations)
fprintf('Number of turns       = %d\n',Best.Turns)
fprintf('Resistance            = %.4f ohm\n',Best.Resistance)
fprintf('Current               = %.4f A\n',Best.Current)
fprintf('Applied MMF           = %.2f At\n',Best.MMF)
fprintf('B at 2.0 mm           = %.4f T\n',Best.B_old)
fprintf('B at 2.1 mm           = %.4f T\n',Best.B_new)
fprintf('Force                 = %.4f N\n',Best.Force)
fprintf('Mass                  = %.4f kg\n',Best.Mass)
fprintf('Weight                = %.4f N\n',Best.Weight)
fprintf('Force/Weight ratio    = %.6f\n',Best.ForceWeightRatio)


%% =========================================================
% 11. PLOT: FORCE VS LAMINATIONS
% =========================================================

figure

scatter( ...
    Results.Laminations, ...
    abs(Results.Force), ...
    20, ...
    Results.Turns, ...
    'filled')

xlabel('Number of Laminations')
ylabel('Magnetic Force (N)')
title('Magnetic Force vs Number of Laminations')
grid on
colorbar


%% =========================================================
% 12. PLOT: FORCE/WEIGHT VS LAMINATIONS
% =========================================================

figure

scatter( ...
    Results.Laminations, ...
    Results.ForceWeightRatio, ...
    20, ...
    Results.Turns, ...
    'filled')

xlabel('Number of Laminations')
ylabel('Force-to-Weight Ratio')
title('Force-to-Weight Ratio vs Number of Laminations')
grid on
colorbar


%% =========================================================
% 13. PLOT: FORCE VS NUMBER OF TURNS
% =========================================================

figure

scatter( ...
    Results.Turns, ...
    abs(Results.Force), ...
    20, ...
    Results.Laminations, ...
    'filled')

xlabel('Number of Coil Turns')
ylabel('Magnetic Force (N)')
title('Magnetic Force vs Number of Coil Turns')
grid on
colorbar


%% =========================================================
% 14. PLOT: MMF VS NUMBER OF TURNS
% =========================================================

figure

plot(Results.Turns,Results.MMF,'o')

xlabel('Number of Coil Turns')
ylabel('Applied MMF (At)')
title('Applied MMF vs Number of Coil Turns')
grid on


%% =========================================================
% 15. SAVE RESULTS
% =========================================================

writetable(Results,'Actuator_Optimisation_Results.xlsx');

fprintf('\n')
fprintf('Optimisation results saved to:\n')
fprintf('Actuator_Optimisation_Results.xlsx\n')


%% =========================================================
% FUNCTION 1: COMPLETE DESIGN CALCULATION
% =========================================================

function result = calculateDesign( ...
    nlam,N,V,D,rhoCu,Pbobbin,mu0,lcore, ...
    tlam,rhoCore,Alam,lgt_old,lgm_old, ...
    lgt_new,lgm_new)

    %% Coil

    Awire = pi*D^2/4;

    lwire = N*Pbobbin;

    Rcoil = rhoCu*lwire/Awire;

    I = V/Rcoil;

    MMF = N*I;


    %% Core thickness

    Tcore = nlam*tlam;


    %% Middle air-gap area

    Agm = Tcore^2;


    %% Core mass

    Vcore = Alam*Tcore;

    mass = Vcore*rhoCore;

    weight = mass*9.81;


    %% B at original air gap

    B_old = solveB( ...
        MMF,lgt_old,lgm_old,lcore,mu0);


    %% Reluctance at original air gap

    phi_old = B_old*Agm;

    R_old = MMF/phi_old;


    %% B at increased air gap

    B_new = solveB( ...
        MMF,lgt_new,lgm_new,lcore,mu0);


    %% Reluctance at increased air gap

    phi_new = B_new*Agm;

    R_new = MMF/phi_new;


    %% dR/dx

    dx = lgt_new-lgt_old;

    dRdx = (R_new-R_old)/dx;


    %% Force

    Force = -0.5*(MMF/R_old)^2*dRdx;


    %% Force-to-weight ratio

    FWratio = abs(Force)/weight;


    %% Store results

    result.Rcoil = Rcoil;
    result.I = I;
    result.MMF = MMF;
    result.B_old = B_old;
    result.B_new = B_new;
    result.R_old = R_old;
    result.R_new = R_new;
    result.dRdx = dRdx;
    result.Force = Force;
    result.mass = mass;
    result.weight = weight;
    result.FWratio = FWratio;

end


%% =========================================================
% FUNCTION 2: ITERATIVE B CALCULATION
% =========================================================

function B = solveB(MMF,lgt,lgm,lcore,mu0)

    %% Initial assumption
    %
    % 40% of the applied MMF is initially assigned
    % to the top air gap.

    Fgt_initial = 0.40*MMF;

    B = (Fgt_initial*mu0)/lgt;


    %% Iteration settings

    tolerance = 0.1;

    maxIterations = 100;


    %% Iteration

    for iteration = 1:maxIterations

        %% Air-gap MMF

        Fgt = (B*lgt)/mu0;

        Fgm = (B*lgm)/mu0;


        %% B-H curve

        H = getH(B);


        %% Core MMF

        Fcore = H*lcore;


        %% Total MMF

        Ftotal = Fgt + Fgm + Fcore;


        %% Error

        error = ((MMF-Ftotal)/MMF)*100;


        %% Convergence

        if abs(error) <= tolerance
            break
        end


        %% Correct B

        B = B*(MMF/Ftotal);


        %% Safety limit for fitted B-H curve

        if B >= 1.60
            B = 1.60;
        end

    end

end


%% =========================================================
% FUNCTION 3: B-H RELATIONSHIP
% =========================================================

function H = getH(B)

    denominator = 1.626-B;

    if denominator <= 0
        error('B has reached the saturation limit of the fitted B-H curve.')
    end

    H = (142.248*B)/denominator;

end
