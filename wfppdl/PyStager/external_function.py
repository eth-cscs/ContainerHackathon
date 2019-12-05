from mpi4py import MPI
from os import walk
import os
import sys
import subprocess
import logging
import time
import hashlib
from os import listdir
from os.path import isfile, join

# ini. MPI
comm = MPI.COMM_WORLD
my_rank = comm.Get_rank()  # rank of the node
p = comm.Get_size()  # number of assigned nods
my_rank = comm.Get_rank()  # rank of the node


# ======================= List of functions ====================================== #
if my_rank == 0:  # node is master

    logger = logging.getLogger(__file__)
    logger.addHandler(logging.StreamHandler(sys.stdout))


def directory_scanner(source_path,load_level):
    # Take a look inside a directories and make a list of ll the folders, sub directories, number of the files and size
    # NOTE : It will neglect if there is a sub-directories inside directories!!!
    # NOTE : It will discriminate between the load level : sub-directories / Files 

    dir_detail_list = []  # directories details
    list_items_to_process = []
    total_size_source = 0
    total_num_files = 0
    list_directories = []
    
    ## =================== Here will be for the Files ================= ##

    if load_level == 1:
        #onlyfiles = []
        #print(source_path)


        #onlyfiles = [f for f in listdir(source_path) if isfile(join(source_path, f))]
        #print(onlyfiles)

        # Listing all the files in the directory 
        for  dirpath, dirnames, filenames in os.walk(source_path): 
            list_items_to_process.extend(filenames)
 
        for f in list_items_to_process :
            path = source_path + str(f)
            statinfo = os.stat(path)         
            size = statinfo.st_size
            total_size_source = total_size_source + int(size)     

        total_num_files  = len(list_items_to_process) # number of the files in the source 
        total_num_directories = int(0)      # TODO need to unify the concept as the number of items 
     
    ## ===================== Here will be for the directories ========== ## 

    if load_level == 0:
        list_directories = []

        list_directories = os.listdir(source_path)

        for d in list_directories:
            # TODO : use os.path.join("foo","bar")
    
            path = source_path + d 
            if os.path.isdir(path):
                list_items_to_process.append(d)
                list_items_to_process.sort()
                num_files = 0
                # size of the files and subdirectories
                size_dir = subprocess.check_output(['du', '-sc', path])
                splitted = size_dir.split()  # fist item is the size of the folder
                size = (splitted[0])
                num_files = len([f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))])
                dir_detail_list.extend([d, size, num_files])
                total_num_files = total_num_files + int(num_files)
                total_size_source = total_size_source + int(size)
            else:
                message = path,'does not exist'
                logger.error(message) 
                     
        total_num_directories = int(len(list_directories))



    ## ======================= End of the Directory case =================== ##
    total_size_source = float(total_size_source / 1000000)  # human readable size source 

    logger.info("=== Directory Scanner output ===")
    message = 'Total size of the source directory is:' + str(total_size_source) + 'Gb.'
    logger.info(message)   
    message = "Total number of the files in the source directory is: " + str(total_num_files)
    logger.info(message)   
    message = "Total number of the directories  in the source directory is: " + str(total_num_directories)
    logger.info(message)   

    # Unifying the naming of this section for both cases : Sub - Directory or File 
    # dir_detail_list == > Including the name of the directories, size and number of teh files in each directory / for files is empty 
    # list_items_to_process    === > List of items to process  (Sub-Directories / Files)
    # total_size_source  === > Total size of the items to process 
    # total_num_files    === > for Sub - Directories : sum of all files in different directories / for Files is sum of all 
    # total_num_directories  === > for Files = 0 
        
    return dir_detail_list, list_items_to_process, total_size_source, total_num_files, total_num_directories

# Source - Directoy 
# Destination Rirectory 
# Dir_detail_list
# list_items_to_process 
# load level

def data_structure_builder (source_dir, destination_dir, dir_detail_list, list_items_to_process,load_level):


    if not os.path.exists(destination_dir):  # check if the Destination dir. is existing
        os_command = ("mkdir " + destination_dir)
        os.system(os_command)
        logger.info('destination path is created')
    else:
        logger.info('The destination path exists')   

            
    os.chdir(destination_dir) # chnage the directory to the destination 

    if load_level == 0:
        logger.info('Load Level = 0 : Data Sctructure will be build')   

        for dir_name in list_items_to_process: 
            #print(dir_name)
            dir_path = destination_dir + dir_name 
        
            # TODO : os.mkdir() it can be cleaned up to use the OS predifnie functions 
            if not os.path.exists(dir_path):           
                #print(dir_name  + " will be created ")
                os_command = ("mkdir " + dir_name)
                os.system(os_command)
                logger.info(dir_name  + " is created ")

    if load_level == 1:
        logger.info('Load Level = 1 : File will be processed')  

    return 



def load_distributor(dir_detail_list, list_items_to_process, total_size_source, total_num_files, total_num_directories,load_level, processor_num):

    # create a dictionary with p number of keys
    # for each directory they add the name to one of the keys
    transfer_dict = dict.fromkeys(list(range(1, processor_num)))
    logger.info("The follwoing is in the load Balancer ")
    logger.info(transfer_dict) 
    logger.info(list_items_to_process)
    logger.info(total_num_directories)
    logger.info(total_num_files)
    print("My MPI rank is : {my_rank}".format(my_rank=my_rank))
    
    # package_counter = 0 possibility to use the counter to fill
    counter = 1

    if load_level == 0:
        for Directory_counter in range(0, total_num_directories):
            if transfer_dict[counter] is None:  # if the value for the key is None add to it
                transfer_dict[counter] = list_items_to_process[Directory_counter]
            else:  # if key has a value join the new value to the old value
                transfer_dict[counter] = "{};{}".format(transfer_dict[counter], list_items_to_process[Directory_counter])
            counter = counter + 1
            if counter == processor_num:
                counter = 1

    if load_level == 1:
        for Directory_counter in range(0, total_num_files):
            if transfer_dict[counter] is None:  # if the value for the key is None add to it
                transfer_dict[counter] = list_items_to_process[Directory_counter]
            else:  # if key has a value join the new value to the old value
                transfer_dict[counter] = "{};{}".format(transfer_dict[counter], list_items_to_process[Directory_counter])
            counter = counter + 1
            if counter == processor_num:
                counter = 1
            
    logging.info(transfer_dict)
    return transfer_dict

def sync_file(source_path, destination_dir, job_name, rsync_status):
    rsync_msg = ("rsync -r " + source_path + job_name + "/" + " " + destination_dir + "/" + job_name)
    # print('Node:', str(my_rank),'will execute :', rsync_str,'\r\n')
    # sync the assigned folder

    if rsync_status == 1:
        os.system(rsync_msg)

    return 



def hash_directory(source_path,job_name,hash_rep_file,input_status):
    #sha256_hash = hashlib.sha256()
    md5_hash = hashlib.md5()

    ########## Create a hashed file repasitory for direcotry(ies) assigned to node #######
    hash_repo_text = input_status + "_"+job_name +"_hashed.txt"
    os.chdir(hash_rep_file)
    hashed_text_note=open(hash_repo_text,"w+")

    # job_name is the name of the subdirectory that is going to be processed 
    directory_to_process = source_path  + job_name
    # print(directory_to_process)
    files_list = []
    for dirpath, dirnames, filenames in os.walk(directory_to_process):
        files_list.extend(filenames)
    
    os.chdir(directory_to_process) # change to the working directory 

    for file_to_process in filenames:
        
        ## ======= this is the sha256 checksum ========= # 
        #with open(file_to_process,"rb") as f:
        #    # Read and update hash in chunks of 4K
        #   for byte_block in iter(lambda: f.read(4096),b""):
        #       sha256_hash.update(byte_block)
        #       hashed_file = sha256_hash.hexdigest()

        with open(file_to_process,"rb") as f:
            # Read and update hash in chunks of 4K
           for byte_block in iter(lambda: f.read(4096),b""):
               md5_hash.update(byte_block)
               hashed_file = md5_hash.hexdigest()

        hashed_text_note.write(hashed_file)

    return 

def md5(fname):
    md5_hash = hashlib.md5()
    with open(fname,"rb") as f:
        # Read and update hash in chunks of 4K
        for byte_block in iter(lambda: f.read(4096),b""):
            md5_hash.update(byte_block)
    return md5_hash.hexdigest()