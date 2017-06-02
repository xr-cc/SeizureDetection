## SUMMARY
Code and brief explanations of data-processing and classification processes of Seizure Onset Detection Problem.<br >
Database used: CHB-MIT Scalp EEG Database<br >
Procedures based on those described in thesis:<br >
Goldberger AL, Amaral LAN, Glass L, Hausdorff JM, Ivanov PCh, Mark RG, Mietus JE, Moody GB, Peng C-K, Stanley HE. PhysioBank, PhysioToolkit, and PhysioNet: Components of a New Research Resource for Complex Physiologic Signals. Circulation 101(23):e215-e220 [Circulation Electronic Pages; http://circ.ahajournals.org/cgi/content/full/101/23/e215]; 2000 (June 13).



## MATLAB CODE
Data Processing and Feauture Generation
####Location: /Code

edf2mat()
* Transform edf. file to mat. file and save it under ../Data/

plotEEG()
* Plot EEG data.

plot_single_file()
* Plot and save EEG data of a single file.
* (If seizure, also plot EEG data around seizure onset. Figure will be closed automatically.)

plot_all_eeg
* Plot EEG of all patients(cases) and all files of each. 

process_patient()
* Process edf files of a specified patient and save them properly.

process_multiple
* Process patients(cases) one by one.

time2sec()
* Convert time to seconds.

get_energy()
* Compute bandwidth-energy and return corresponding matrix

get_seg_feature()
* Generate features for a segment of data.

get_patient_feature()
* Generate features from all files of a patient and save to file.

get_patient_feature_separately
* Generate features and corresponding labels seperately.

get_patient_feature_simultaneously
* Generate features and corresponding labels at the same time.

get_patient_feature2
* functioning as function get_patient_feature()

get_patient_feature_minusL
* Generate features and corresponding labels seperately.
* (need modification of data range in get_seg_feature())



edfread() [Copyright 2009 - 2012 MathWorks, Inc.]
* Read European Data Format file into MATLAB

edfreadUntilDone() [Copyright 2009 - 2012 MathWorks, Inc.]
* Read European Data Format file into MATLAB



plotFFT()
* Plot FFT of data (single channel).

extract_single_file()
* Plot EEG data of a single file and plot fft of specified channel.
* (If seizure, plot EEG data around seizure onset and FFT for entire seizure time;If non-seizure, plot EEG for speicified time range and FFT for entire data segment.)

Edf_To_Mat_file
* Example of transfering edf to mat.

Edf_To_Mat_Select18
* Example of selecting certain channels when transfering edf to mat.

read_summary
* read in summary of a specific patient(case)

extract_feature()
* not used (old version)

generate_feature_by_record()
* Generate features by record and save to file(seg).
* not used (old version)



## PYTHON CODE
Classification and Performance Measurement
####Location: /PythonCode

correlation
* Calculate correlation (p-values) of features of specific case.

loo_seizure_pattern
* Leave one seizure record out and measure sensitivity and latency based on 6s-alarm-pattern.

loo_seizure_pattern_iter
* Leave one seizure record out and measure sensitivity and latency based on (6s)-alarm-setting.
* Iterate for (iter) times and average the results.

loo_nonseizure_fa
* Leave one non-seizure record out and calculate false alarm rates (measure specificity).

loo_nonseizure_fa_iter
* Leave one non-seizure record out and calculate false alarm rates (measure specificity).
* Iterate for (iter) times and average the results.



svm_split
* Split data into training and testing set.
* Use SVM model.
* Measure basic performances.
* Iterate for (iter) times and average the results.

lr_split
* Split data into training and testing set.
* Use Logistic Regression model.
* Measure basic performances.
* Iterate for (iter) times and average the results.

svm_loo
* Leave one data point out.
* Use SVM model.
* Measure basic performances.
* Iterate for (iter) times and average the results.

new_sensitivity
* Leave one seizure record out and measure sensitivity and latency based on 6s-alarm-pattern.
* (used for features generated from get_patient_feature_simultaneously)

new_specificity
* Leave one non-seizure record out and calculate false alarm rates (measure specificity).
* (used for features generated from get_patient_feature_simultaneously)



leave_one_seizure_data_out
* Leave one seizure data point out and measure performances.

loo_fp
* Leave one non-seizure data point out.
* Measure accuracy and data point false positive rate.

loo_seizure
* Leave one seizure record out and measure performances based on data points.

loo_seizure_unbalance
* Leave one seizure record out and measure performances based on data points.
* Data unbalanced.

loo_seizure_iter
* Leave one seizure record out and measure performances based on data points.
* Iterate for (iter) times and average the results.
