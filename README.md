# LabelMeFacade

Date created: 03-Sep-2010

Authors: Bjoern Froehlich and Erik Rodner

This is the LabelMeFacade Image Dataset, which we created from LabelMe images for semantic segmentation research. Since this is a subset of LabelMe images, the images were originally collected by the authors of http://publications.csail.mit.edu/tmp/MIT-CSAIL-TR-2005-056.pdf . All images should only be used for non-commercial and research experiments. Please check with the authors of the LabelMe dataset, in case you are unsure about the respective copyrights and how they apply.

## Colors and subsets

The dataset contains 100 images for training and 845 images for testing (see train.txt and test.txt for details).
Color codes for labels are (in R:G:B):
    
    various = 0:0:0
    building = 128:0:0
    car = 128:0:128
    door = 128:128:0
    pavement = 128:128:128
    road = 128:64:0
    sky = 0:128:128
    vegetation = 0:128:0
    window = 0:0:128

## Citation

If you use this database please cite one of the following papers:

    @INPROCEEDINGS{Froehlich-Rodner-Denzler-ICPR2010,
	    author = {Bj{\"o}rn Fr{\"o}hlich and Erik Rodner and Joachim Denzler},
    	title = {A Fast Approach for Pixelwise Labeling of Facade Images},
	    booktitle = {Proceedings of the International Conference on Pattern Recognition
    	(ICPR 2010)},
    	year = {2010},
    }

    @inproceedings{Brust15:ECP,
        author = {Clemens-Alexander Brust and Sven Sickert and Marcel Simon and Erik Rodner and Joachim Denzler},
        booktitle = {CVPR Workshop on Scene Understanding (CVPR-WS)},
        title = {Efficient Convolutional Patch Networks for Scene Understanding},
        year = {2015},
    }

