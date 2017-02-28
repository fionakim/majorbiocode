# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/2/28 16:42

import os,subprocess
import re
from bs4 import BeautifulSoup


def check_multi_folder(dir_name, root_eg):
    sub_lst = dir_name.split('/')
    for ele in sub_lst:
        root_eg = '/'.join([root_eg.rstrip('/'), ele])
        if not os.path.isdir(root_eg):
            os.mkdir(root_eg)


root = '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/igv_test/seqrise/html'
html = BeautifulSoup(open('/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/igv_test/seqrise/file_site.htm').read(),
                     'html.parser')

# root = 'Z:\\majorbio-linfang.jin\\javascript\\seqrise'
# html = BeautifulSoup(open('Z:\\majorbio-linfang.jin\\javascript\\tmp\\file_site.htm').read(),
#                      'html.parser')
script_lst = html.find_all('script')
link_tags = html.find_all('link')
link_lst = []
for e in script_lst:
    if e.has_attr('src'):
        link = e.attrs['src']
        if re.match(r'^http(s)?://\S+\.(js|css)$', link):
            link_lst.append(link)

for tag in link_tags:
    if tag.has_attr('href'):
        link = tag.attrs['href']
        if re.match(r'^http(s)?://\S+\.\w+$', link):
            link_lst.append(link)

a_lst = html.find('body').find_all('a')

for a in a_lst:
    if a.has_attr('src'):
        href = a.attrs['src']
        if re.match(r'http(s)?://\S+\.\w+$', href):
            link_lst.append(href)

for link in link_lst:
    m = re.match(r'^http.*://seqrise\.com/(\S+)/([^/]+)$', link)
    if m:
        sub_path = m.group(1)
        print sub_path
        dir_name = os.path.join(root, sub_path)
        check_multi_folder(sub_path, root)
        subprocess.call('wget {}  -c -P  {}'.format(link, dir_name), shell=True)
    else:
        print link
