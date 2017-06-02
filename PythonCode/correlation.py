#!/usr/bin/env python
"""
Calculate correlation (p-values) of features of specific case.
"""
import scipy.io
import numpy as np
from sklearn import feature_selection
import os

case = '01'

features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels.mat')
labels = labels_mat['labels']
features = features_mat['features']

T = len(features[0][0][0]) # 8*18*3*N
feature_inputs = []
label_inputs = []
N = range(T)
for i in N:
    feature = features[:,:,:,i]
    a = np.array(feature)
    feature = a.flatten()
    feature_inputs.append(feature)
    label_inputs.append(labels[0][i])

label_inputs = np.array(label_inputs)
feature_inputs = np.array(feature_inputs)

# f-regression
fre = feature_selection.f_regression(feature_inputs, label_inputs, center=True)
fvalues = fre[0]
pvalues = fre[1]
# print fvalues
# print "P Values"
# print pvalues

print "Percentage of highly significance: ", float(sum(1 for pv in pvalues if pv<0.001))/len(pvalues)
print "Percentage of p<0.01: ", float(sum(1 for pv in pvalues if pv<0.01))/len(pvalues)

# # save to measurements directory
# meas_path = '../Measurements/chb'+case+'meas'
# if not os.path.exists(meas_path):
#     os.makedirs(meas_path)
# scipy.io.savemat(meas_path+'/SNchb'+case+'correlation.mat',
#                  {'fvalues':fvalues, 'pvalues':pvalues})
# meas_note_path = '../Measurements/'
# with open(meas_note_path+"note"+case+".txt", "a") as myfile:
#     myfile.write(case+"\n")
#     myfile.write("correlation")
#     myfile.write("Percentage of highly significance: "+str(float(sum(1 for pv in pvalues if pv<0.001))/len(pvalues))+"\n")
#     myfile.write("Percentage of p<0.01: "+str(float(sum(1 for pv in pvalues if pv<0.01))/len(pvalues))+"\n\n")

