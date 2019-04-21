#!/usr/bin/python
#
################################################################################
# avi2mp4.py
# This script converts videos from avi to h.264 or h.265
#
################################################################################
# TODOs
#
################################################################################

__author__ = "George Langdin (george@langdin.com)"
__version__ = "1"
__copyright__ = "Copyright (c) George Langdin"
__license__ = ""

################################################################################
# Import stuff
################################################################################

import sys			#
import os			# OS commands
import argparse		# Cmd line arg parser - requires 2.7
import array		#
import socket		# Network
import time			#
import ConfigParser # Config file parser
import logging

# Multiprocessing support so we can do multiple conversions at once, leveraging
# multiple CPU cores
from multiprocessing import Pool, Queue, freeze_support

done_list=[]

################################################################################
# Functions
################################################################################

def parse_args():
	arg_parser = argparse.ArgumentParser()

	arg_parser.add_argument('-v', '--verbose', action='count', default=0,
		help='increase output')
	arg_parser.add_argument('-V', '--version', action='version',
		version='avi2mp4.py 1.0', help='Print version')

	arg_parser.add_argument('file_list', nargs='+', help='input files')
	arg_parser.add_argument('output_dir', help='output directory')

	return arg_parser.parse_args()

#-------------------------------------------------------------------------------

def process_file(file):
	# TODO: Run ffmpeg
	return file

#-------------------------------------------------------------------------------

def log_result(result):
    # This is called when process_file returns a result.
    # done_list is modified only by the main process, not the pool workers.
    done_list.append(result)

#-------------------------------------------------------------------------------

def main():
	# Parse command line arguments
	args = parse_args()

	# Queue to hold results of processing
	done_queue = Queue()

	# By default this creates one process per CPU core
	pool = Pool()

	#Start worker processes
	for file in args.file_list:
		print "file: " + file
		pool.apply_async(process_file, args = (file, ), callback = log_result)

	pool.close()
	pool.join()
	print done_list

#	result = pool.apply_async(f, (10,))	  # evaluate "f(10)" asynchronously in a single process
#	print result.get(timeout=1)			  # prints "100" unless your computer is *very* slow

#	result = pool.apply_async(time.sleep, (10,))
#	print result.get(timeout=1)			  # raises multiprocessing.TimeoutError


################################################################################
# Main
################################################################################

if __name__ == "__main__":
	freeze_support()
	main()






#  from threading import Thread
# from queue import Queue
#
#
# q = Queue()
#
# def check_voucher(code)
#     # check the code with a HTTP request
#     pass
#
# # The worker thread pulls an item from the queue and processes it
# def worker():
#     while True:
#         item = q.get()
#         check_voucher(item)
#         q.task_done()
#
# # Create the thread pool.
# for i in range(10):
#     t = Thread(target=worker)
#     # Thread dies when main thread (only non-daemon thread) exits.
#     t.daemon = True
#     t.start()
#
# # Now we have 10 worker threads running and waiting for items to
# # appear on the queue.
#
# # Put work items on the queue.
# for x in list(range(0, 99999)):
#     potential_voucher = str(x).zfill(5)
#     q.put(potential_voucher)
#
# # Block until all tasks are done
# q.join()