%% Point to the datasets

dc = PierreEricLFADS.DatasetCollection('/data2/lfads/PierreEric/export_v02_broadbandRethreshNonSorted');
dc.autoDetectDatasets();

dc.loadInfo;
dc.filterHasHighSNRChannels();
dc.filterBestSaveTagEachDate();

%% Set parameters

par = PierreEricLFADS.RunParams;
par.spikeBinMs = 10;
par.batchSize = 40;
par.nTrialsKeep = 500;
par.regularizerIncreaseSteps = 100;
par.learningRateDecayFactor = 0.95;

rc = PierreEricLFADS.RunCollection('/data2/lfads/PierreEric/runs', 'oneVsTwo_0922_0921', dc, par);

%% PM done
r = PierreEricLFADS.Run('one_0914', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-14.saveTagGroup_1_export');

%% PM done
r = PierreEricLFADS.Run('one_0915', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-15.saveTagGroup_1_export');

%% PM done
r = PierreEricLFADS.Run('one_0916', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-16.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one_0917', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-17.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one_0920', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-20.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one0921', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-21.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one0922', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-22.saveTagGroup_1_export');

%% PM done
r = PierreEricLFADS.Run('one0923', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-23.saveTagGroup_1_export');

%% Pm done
r = PierreEricLFADS.Run('one_0926', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-26.saveTagGroup_1_export');

%% PM done
r = PierreEricLFADS.Run('one_0927', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-27.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one_0928', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-28.saveTagGroup_2_export');

%% PM done
r = PierreEricLFADS.Run('one_0929', rc);
r.version = 1;
r.selectDatasetsByName('subject_Pierre.date_2016-09-29.saveTagGroup_2_export');

%% Second run collection for the single stitched dataset

rcAll = rc.copyClearRuns();

r = PierreEricLFADS.Run('all', rcAll);
r.version = 1;
r.selectDatasetsByIndex(1:rc.nDatasets);

%% predict peak speed for both single day and multi-day-stitched from generator ICS
clear singlePred;
for iR = 1:rc.nRuns
    r = rc.runs(iR);
    singlePred(iR) = r.predictPeakSpeedFromInitialConditions();
end

r = rcAll.runs(1);
allPred = r.predictPeakSpeedFromInitialConditions();

%% Plot rho for predicting peak speed from single day vs. stitched for generator ICS


singleRho = [singlePred.cvRho];
allRho = [allPred.cvRho];

clf;
scatter(singleRho, allRho);
hold on;
TrialDataUtilities.Plotting.identityLine;
xlabel('Single Day \rho');
ylabel('Stitched 12-Day\rho');
% AutoAxis.replace();

%% Generate curves of predictive power of generator states vs. time

clear singlePredGen;
prog = ProgressBar(rc.nRuns, 'Predicting peak speed for %d runs', rc.nRuns);
for iR = 1:rc.nRuns
    prog.update(iR);
    r = rc.runs(iR);
    singlePredGen(iR) = r.predictPeakSpeedFromGeneratorStatesEachTime();
end
prog.finish();

r = rcAll.runs(1);
allPredGen = r.predictPeakSpeedFromGeneratorStatesEachTime();

%% Plot predictive power of generator states vs. time

% Time x nDatasets
singleRhoMat = cat(1, singlePredGen.cvRho)';
allRhoMat = cat(1, allPredGen.cvRho)';

figUnique('rho vs. time');
tvec = -400:10:490;
plot(tvec, singleRhoMat, 'k-');
hold on;
plot(tvec, allRhoMat, 'r-');
xlabel('Time from Move (ms)');
ylabel('CV \rho');

%% Plot scatter of best time for single days

[~, bestIdx] = max(sum(singleRhoMat, 2));

singleRho = singleRhoMat(bestIdx, :)';
allRho = allRhoMat(bestIdx, :)';

clf;
scatter(singleRho, allRho);
hold on;
TrialDataUtilities.Plotting.identityLine;
xlabel('Single Day \rho');
ylabel('Stitched 12-Day\rho');
axis tight
title('Generator state best time');

% %%
% r = LFADS.Run('four0921_0922_0923_0926');
% rc.addRun(r);
% r.selectDatasets([6 7 8 9]);
% r.prepareForLFADS();

%% try again with generator states





%%
rc.writeTensorboardShellScript

%%

r = rc.runs(1);

seqData = r.loadSequenceFiles();
pmData = r.loadPosteriorMeanSamples();

seq = seqData{1};
pm = pmData{1};

% which condition is each trial
[cnames, ~, cond] = unique({seq.targetDirectionName});
nC = numel(cnames);

%% plot the factors colored by condition

clf
cmap = TrialDataUtilities.Color.hslmap(nC);
% factors is nFactors x nTimeBins x nTrials
nFactors = size(pm.factors, 1);
for iF = 1:nFactors
    subtightplot(nC, 1, iF);
    for iC = 1:nC
       h = plot(squeeze(pm.factors(iF, :, cond == iC)), 'Color', cmap(iC, :));
       TrialDataUtilities.Plotting.setLineOpacity(h, 0.3);
       hold on;
       axis tight, box off;
    end
end


%% plot the controller outputs colored by condition

clf
cmap = TrialDataUtilities.Color.hslmap(nC);
% factors is nFactors x nTimeBins x nTrials
nInputs = size(pm.controller_outputs, 1);
for iF = 1:nInputs
    subtightplot(nInputs, 1, iF);
    for iC = 1:nC
       h = plot(squeeze(pm.controller_outputs(iF, :, cond == iC)), 'Color', cmap(iC, :));
       TrialDataUtilities.Plotting.setLineOpacity(h, 0.3);
       hold on;
       axis tight, box off;
    end
end

%% try a decode using two day

r = rc.runs(1);

seqData = r.loadSequenceFiles();
pmData = r.loadPosteriorMeanSamples();

seq = seqData{1};
pm = pmData{1};
[res_lfads_twoDay, res_neural_twoDay] = LFADS.decodeKinematicsFromLFADSFactors(seq, pm);

figUnique(r.name);
LFADS.compareKinematicDecodes(seq, {res_lfads_twoDay, res_neural_twoDay}, 'colormap', {'b', 'r'});

%% decode using one day

r = rc.runs(2);

seqData = r.loadSequenceFiles();
pmData = r.loadPosteriorMeanSamples();

seq = seqData{1};
pm = pmData{1};
[res_lfads_0921, res_neural_0921] = LFADS.decodeKinematicsFromLFADSFactors(seq, pm);

figUnique(r.name);
LFADS.compareKinematicDecodes(seq, {res_lfads_0921, res_neural_0921}, 'colormap', {'b', 'r'});

%% grab generator state a few timesteps in as the intiial condition

% nGenUnits x nTrials
ics = squeeze(pm.generator_states(:, 3, :));

% which condition is each trial
cnames = {'DownRight', 'Right', 'UpRight', 'Up', 'UpLeft', 'Left', 'DownLeft'};
[~, cond] = ismember({seq.targetDirectionName}, cnames);

nC = numel(cnames);

clf;
% ics_tsne = tsne(ics', cond)';
ics_tsne = tsne(ics', [])'; % 2 x nTrials

for iC = 1:nC
   h = plot(ics_tsne(1, cond == iC), ics_tsne(2, cond == iC), 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', cmap(iC, :));
   TrialDataUtilities.Plotting.showFirstInLegend(h, cnames{iC});
   hold on;
end
legend(gca, 'show');


