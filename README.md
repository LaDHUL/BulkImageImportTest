
# Bash script to test a massing bulk import of images into Knora

0. Clone the project somewhere and move in: 

```shell
$ git clone https://github.com/LaDHUL/BulkImageImportTest.git
$ cd BulkImageImportTest
```

1. Have a running Knora stack (http://localhost:3333) containing the `anything` ontology

2. Prepare a folder containing all image files

3. Depending of the image format of your files, if necessary add to the `mimetypes` file the missing format (`file extension:mimetypes`)

4. The test will launch:

- one bulk import per accepted file (that is, mimetypes managed)
- a full bulk import of all images

Launch the test:

```shell
$ ./checkImageFolder.sh {full_path_to_image_folder} > log &
$ tail -f log
```

Print out only errors and warnings:
```shell
$ egrep "ERROR|WARN" log
```








