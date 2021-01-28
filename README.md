## COE3DQ5 project

### Objective

The main objective of the COE3DQ5 project is to make students comfortable to work on a larger design (than the labs) that also includes the hardware implementation of several types of digital signal processing algorithms. In addition, the hardware design and implementation must meet some latency constraints (defined indirectly through multiplier utilization constraints), while ensuring that hardware resources are not wasted.

### Preparation

This repo contains a carbon copy of the released code for experiment 4 from lab 5, which is the start-up code for the project. However, there are two main additions: a software model of the image decoder in the `sw` subfolder and the backbone code for some additional testbenches (in the `tb` subfolder, which can be compiled to replace the lab 5 experiment 4 testbench by updating `compile.do` in the `sim` subfolder).

* Revise the five labs
* Read [this](doc/3dq5-2020-project-description.pdf) detailed project document and get familiarized with the software model from the `sw` subfolder 
* Attend the forthcoming classes because they are focused almost exclusively on the project (conceptual understanding, main challenges, thought process, design decisions, verification plan, ...)
* If needed, any updates, changes, revisions, ... will be communicated to the entire class in due time

### Evaluation

Push your source code and the 6-page report in GitHub before November 30 at 11 pm. The report should be in PDF format and should be placed in the `doc` subfolder. Further details concerning the expectations for the project report and the cross-examinations in the week of November 30 will be provided in due time.
