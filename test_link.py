import os 
# old_d = "/mnt/ilustre/users/sanger-dev/workspace/20170204/Single_mapsplice_map_linfang_0002/MapspliceMap"
# new_d = "/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test/link_test"
# old_files = [os.path.join(old_d, i) for i in os.listdir(old_d)]
#
# for f in old_files:
#     if os.path.isfile(f):
#         os.symlink(f,os.path.join(new_d, os.path.basename(f)))
#     if os.path.isdir(f):
#         os.symlink(f,os.path.join(new_d, os.path.basename(f)))

f = "/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/fq_list"
new_dir = "/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/test_fq"
with open(f) as fr:
    files = fr.readlines()
    for path in files:
        file_name = os.path.basename(path.strip())
        if os.path.isfile(path.strip()):
            os.symlink(path.strip(),os.path.join(new_dir,file_name))

