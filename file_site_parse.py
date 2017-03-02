# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/2/28 16:42

import os, subprocess
import re
from bs4 import BeautifulSoup


def check_multi_folder(dir_name, root_eg):
	sub_lst = dir_name.split('/')
	for ele in sub_lst:
		root_eg = '/'.join([root_eg.rstrip('/'), ele])
		if not os.path.isdir(root_eg):
			os.mkdir(root_eg)


#
root = '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/igv_test/seqrise/html'
html = '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/igv_test/seqrise/seqrise.html'
# root = 'Z:\\majorbio-linfang.jin\\javascript\\seqrise'
# html ='Z:\\majorbio-linfang.jin\\javascript\\tmp\\seqrise.html'

content = open(html).read()

link_pattern = re.compile(r'(https://seqrise\.com/[\w\/\.]+)')
link_lst = link_pattern.findall(str(content))
print link_lst
print len(link_lst)

# try:
# 	while True:
# 		tag = tag_lst.next()
# 		m = re.match(r'.+=.(https://(\S+/)+[\w_-]+\.\w+).\s+', str(tag))
# 		if m:
# 			link = m.group(1)
# 			link_set.add(link)
# 			print link
# except StopIteration:
# 	pass

# for e in script_lst:
#     if e.has_attr('src'):
#         link = e.attrs['src']
#         if re.match(r'^http(s)?://\S+\.(js|css)$', link):
#             link_set.append(link)
#
# for tag in link_tags:
#     if tag.has_attr('href'):
#         link = tag.attrs['href']
#         if re.match(r'^http(s)?://\S+\.\w+$', link):
#             link_set.append(link)
#
# a_lst = html.find('body').find_all('a')
#
# for a in a_lst:
#     if a.has_attr('src'):
#         href = a.attrs['src']
#         if re.match(r'http(s)?://\S+\.\w+$', href):
#             link_set.append(href)

link_set = set(link_lst)
for link in link_set:
	
	m = re.match(r'^https://seqrise\.com/([^/]+/)*([^/\.]+\.)+[^/\.]+$', str(link))
	if m:
		sub_path = m.group(1)
		if not sub_path:
			sub_path = ''
		dir_name = os.path.join(root, sub_path)
		check_multi_folder(sub_path, root)
		print sub_path
		subprocess.call('wget {}  -c -P  {}'.format(link, dir_name), shell=True)
	
