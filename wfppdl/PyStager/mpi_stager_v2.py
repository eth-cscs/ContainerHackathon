from mpi4py import MPI
from os import walk
import sys
import subprocess
import logging
import time
from external_function import directory_scanner
from external_function import load_distributor
from external_function import hash_directory
from external_function import data_structure_builder
from external_function import md5
import os

# How to Run it! 
# mpirun -np 6 python mpi_stager_v2.py  
# mpiexec -np 6 python mpi_stager_v2.py  


# for the local machine test
current_path = os.path.dirname(os.path.abspath(__file__))
os.chdir(current_path)
time.sleep(0)

# ini. MPI
comm = MPI.COMM_WORLD
my_rank = comm.Get_rank()  # rank of the node
p = comm.Get_size()  # number of assigned nods

print('Number of the CPU assigned')
print(p)



# ================================== ALL Nodes:  Read-in parameters ====================================== #

fileName = "parameters.dat"  # input parameters file
fileObj = open(fileName)
params = {}

for line in fileObj:
    line = line.strip()
    read_in_value = line.split("=")
    if len(read_in_value) == 2:
        params[read_in_value[0].strip()] = read_in_value[1].strip()

# input from the user:
source_dir = str(params["Source_Directory"])
destination_dir = str(params["Destination_Directory"])
log_dir = str(params["Log_Directory"])
rsync_status = int(params["Rsync_Status"])
checksum_status = int(params["Checksum_Status"])
load_level = int(params["Load_Level"])

# ==================================== Master Logging ==================================================== #
# DEBUG: Detailed information, typically of interest only when diagnosing problems.
# INFO: Confirmation that things are working as expected.
# WARNING: An indication that something unexpected happened, or indicative of some problem in the near
# ERROR: Due to a more serious problem, the software has not been able to perform some function.
# CRITICAL: A serious error, indicating that the program itself may be unable to continue running.
# It will copy the logging messages to the stdout, for the case of container version on HPC 

if my_rank == 0:  # node is master
    logging.basicConfig(filename='pystager.log', level=logging.DEBUG,
                        format='%(asctime)s:%(levelname)s:%(message)s')
    logger = logging.getLogger(__file__)
    logger.addHandler(logging.StreamHandler(sys.stdout))

    start = time.time()  # start of the MPI
    logger.info(' === PyStager is started === ')


# check the existence of the  source path :

if not os.path.exists(source_dir):  # check if the source dir. is existing
    if my_rank == 0:
        logger.critical('The source does not exist')
        logger.info('exit status : 1')

    ## TODO : comminication to exit for all Nodes or self-termination termination 

    sys.exit(1)


if my_rank == 0:  # node is master

    # ==================================== Master : Directory scanner ================================= #

    print("The source path is  : {path}".format(path=source_dir))
    print("The destination path is  : {path}".format(path=destination_dir))

    logger.info("==== Directory scanner : start ====")
    ret_dir_scanner = directory_scanner(source_dir,load_level)
    #print(ret_dir_scanner)

    # Unifying the naming of this section for both cases : Sub - Directory or File 
    # dir_detail_list == > Including the name of the directories, size and number of teh files in each directory / for files is empty 
    # list_items_to_process    === > List of items to process  (Sub-Directories / Files)
    # total_size_source  === > Total size of the items to process 
    # total_num_files    === > for Sub - Directories : sum of all files in different directories / for Files is sum of all 
    # total_num_directories  === > for Files = 0 

    dir_detail_list = ret_dir_scanner[0]
    list_items_to_process = ret_dir_scanner[1]
    total_size_source = ret_dir_scanner[2]
    total_num_files = ret_dir_scanner[3]
    total_num_dir = ret_dir_scanner[4]
    logger.info("==== Directory scanner : end ====")

    # ================================= Master : Data Structure Builder ========================= #

    logger.info("==== Data Structure Builder : start  ====")     
    data_structure_builder(source_dir, destination_dir, dir_detail_list, list_items_to_process,load_level)
    logger.info("==== Data Structure Builder : end  ====") 

    # ===================================  Master : Load Distribution   ========================== #

    logger.info("==== Load Distribution  : start  ====")  
    #def load_distributor(dir_detail_list, sub_dir_list, total_size_source, total_num_files, total_num_directories, p):
    ret_load_balancer = load_distributor(dir_detail_list, list_items_to_process, total_size_source, total_num_files, total_num_dir,load_level, p)
    transfer_dict = ret_load_balancer
    logger.info(ret_load_balancer) 
    logger.info("==== Load Distribution  : end  ====") 

    # ===================================== Master : Send / Receive =============================== #

    logger.info("==== Master Communication  : start  ====") 

    # Send : the list of the directories to the nodes
    for nodes in range(1, p):
        broadcast_list = transfer_dict[nodes]
        comm.send(broadcast_list, dest=nodes)
    
    # Receive : will wait for a certain time to see if it will receive any critical error from the slaves nodes
    idle_counter = p - len(list_items_to_process)
    while idle_counter > 1:  # non-blocking receive function
        message_in = comm.recv()
        logger.warning(message_in)
        #print('Warning:', message_in)
        idle_counter = idle_counter - 1
    
    # Receive : Message from slave nodes confirming the sync
    message_counter = 1
    while message_counter <= len(list_items_to_process):  # non-blocking receive function
        message_in = comm.recv()
        logger.info(message_in)
        message_counter = message_counter + 1

    # stamp the end of the runtime
    end = time.time()
    logger.debug(end - start)
    logger.info('==== PyStager is done ====')
    logger.info('exit status : 0')
  

    sys.exit(0)

else:  # node is slave
    
    # ============================================= Slave : Send / Receive ============================================ #
    message_in = comm.recv()

    if message_in is None:  # in case more than number of the dir. processor is assigned todo Tag it!
        message_out = ('Node', str(my_rank), 'is idle')
        comm.send(message_out, dest=0)

    else: # if the Slave node has joblist to do
        job_list = message_in.split(';')

        for job_count in range(0, len(job_list)):
            job = job_list[job_count] # job is the name of the directory(ies) assigned to slave_node
            #print(job)
            
            # ======= Directory Level ====== # 
            if load_level == 0:

                # creat a checksum ( hash) from the source folder. 
                if checksum_status == 1: 
                    hash_directory(source_dir,job,current_path,"source")

                if rsync_status == 1:
                    # prepare the rsync commoand to be excexuted by the worker node 
                    rsync_str = ("rsync -r " + source_dir + job + "/" + " " + destination_dir + "/" + job)
                    os.system(rsync_str)
                    if checksum_status == 1:
                        hash_directory(destination_dir,job,current_path,"destination")
                        os.chdir(current_path)
                        source_hash_text = "source" + "_"+ job +"_hashed.txt"
                        destination_hash_text = "destination"  + "_"+ job +"_hashed.txt" 
                        if md5(source_hash_text) == md5(destination_hash_text):
                            msg_out = 'source: ' + job +' and destination: ' + job +' files are identical' 
                            print(msg_out)
                            os.remove(source_hash_text)
                            os.remove(destination_hash_text)

                        else:
                            msg_out = 'integrity of source: ' + job +' and destination: ' + job +' files could not be verified' 
                            print(msg_out)
                else :
                    rsync_str = (" Opereation requested on the " + source_dir + job )



            # ======= File Level ====== # 

            if load_level == 1:
                
                ## creat a checksum ( hash) from the source folder.  TODO : chnage to file hash
                #if checksum_status == 1: 
                #    hash_directory(source_dir,job,current_path,"source")

                if rsync_status == 1:
                    # prepare the rsync commoand to be excexuted by the worker node 
                    rsync_str = ("rsync  " + source_dir + "/" + job  + " " + destination_dir + "/" + job)
                    os.system(rsync_str)
                    #if checksum_status == 1:
                    #    hash_directory(destination_dir,job,current_path,"destination")
                    #    os.chdir(current_path)
                    #    source_hash_text = "source" + "_"+ job +"_hashed.txt"
                    #    destination_hash_text = "destination"  + "_"+ job +"_hashed.txt" 
                    #    if md5(source_hash_text) == md5(destination_hash_text):
                    #        msg_out = 'source: ' + job +' and destination: ' + job +' files are identical' 
                    #        print(msg_out)
                    #        os.remove(source_hash_text)
                    #        os.remove(destination_hash_text)
                    #
                    #    else:
                    #        msg_out = 'integrity of source: ' + job +' and destination: ' + job +' files could not be verified' 
                    #        print(msg_out)
                else :
                    rsync_str = (" Opereation requested on the " + source_dir + job )



            # Send : the finish of the sync message back to master node

            message_out = ('Node:', str(my_rank), 'finished :', rsync_str, '\r\n')
            comm.send(message_out, dest=0)

MPI.Finalize()
