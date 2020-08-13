# FixDateTaken
Some picture don't have "Date Taken" property, if lucky, the "Date Created" is correct, then you can use my scripts to fix the taken date.
   1) This solution only works if the "Date Create" is correct. 
   2) This script only fix .jpeg and .jpg image files.

The scripcmdlet outputs FileInfo objects and check if "Date Taken" exisits, if yes, skip; if no, update the property with "Date Create". 

## Before 
![img](https://raw.githubusercontent.com/lesca/FixDateTaken/master/images/before.png)

## Progress
![img](https://raw.githubusercontent.com/lesca/FixDateTaken/master/images/Progress.png)

## After
![img](https://raw.githubusercontent.com/lesca/FixDateTaken/master/images/after.png)

