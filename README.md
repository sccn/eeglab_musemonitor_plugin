# Mind Monitor (formerly Muse Monitor) EEGLAB plugin

The repository for this plugin is located at [here](https://github.com/sccn/eeglab_musemonitor_plugin).

If this plugin does not work for you, see also this [other independent implementation](https://github.com/amisepa/import_muse).

If you want to fix bugs, please issue a pull request.

# Automated artifact rejection

The plugin features automated artifact rejection as outlined in this [paper](https://ieeexplore.ieee.org/document/9669415). The best method for rejecting EEG channels is based on detecting abnormal spectrum, and the best method for rejecting continuous data segments is the Artifact Subspace Reconstruction; these automated methods, validated against human raters, showed no significant difference from and potentially outperformed human raters. The GUI is shown below. To use automated artifact rejection, check the checkbox for filtering the data and for rejecting bad portions using ASR.

![muse_gui](https://github.com/sccn/eeglab_musemonitor_plugin/assets/1872705/8f6b3cd2-6599-4461-8d8b-cde220d208f9)

# Testimonial

"We were throwing away 30% of our Muse data. With this plugin, we are able to to keep 95% of the data." Olav Krigolson, author of "[Using Muse: Rapid Mobile Assessment of Brain Performance](https://www.frontiersin.org/journals/neuroscience/articles/10.3389/fnins.2021.634147/full)" and "[Choosing MUSE: Validation of a Low-Cost, Portable EEG System for ERP Research](https://www.frontiersin.org/journals/neuroscience/articles/10.3389/fnins.2017.00109/full)."

# Version history

version 4.0
- Allow cleaning the data when it is being imported

version 3.2
- Better automatic calculation of sampling rate

version 3.1
- Remove typo in code that made it crash

version 3
- Now allows to set the sampling rate or detect it automatically

version 2
- Now allows to import more than EEG channels

