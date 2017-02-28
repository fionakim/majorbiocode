# -*- coding: utf-8 -*-
# __author__ = 'sheng.he'
# 脚本用于规范化注释物种信息格式化，两个参数，第一个是旧的物种注释文件，必须得有 8 层物种， 第二个为新的物种注释文件
import sys
from collections import defaultdict
check_dict = {}

class TaxonTree(object):
	def __init__(self, name, parent=None):
		self._parent = parent
		self._name = name
		self.new_name = name
		self._children = {}
		self.num = 0
		self.seq_id = []
	
	def parse(self, taxs):
		self.num += 1
		if len(taxs) == 2:
			if taxs[0] not in self._children:
				self._children[taxs[0]] = TaxonTree(taxs[0], parent=self).parse_id(taxs[1])
			else:
				self._children[taxs[0]].parse_id(taxs[1])
		else:
			if taxs[0] not in self._children:
				self._children[taxs[0]] = TaxonTree(taxs[0], parent=self).parse(taxs[1:])
			else:
				self._children[taxs[0]].parse(taxs[1:])
		return self
	
	def parse_id(self, seqid):
		self.num += 1
		self.seq_id.append(seqid)
		return self
	
	def get_good_parent(self):
		if self._parent and isinstance(self._parent._name, str) and '__' in self._parent._name:
			if self._parent._name.split('__')[-1] in ['norank', 'uncultured', "Incertae_Sedis",
			                                          "unidentified", "Unclassified", "Unknown"]:
				return self._parent.get_good_parent()
			else:
				return self._parent
		else:
			return self._parent
	
	def all_parent_name(self, taxs):
		if self._parent:
			taxs.insert(0, self.new_name)
			self._parent.all_parent_name(taxs)
	
	def new_tax(self):
		self.new_tax_str = []
		self.all_parent_name(self.new_tax_str)
		return ';'.join(self.new_tax_str)


def parse_file(fp):
	origin_tree = TaxonTree(0)
	taxon_f = open(fp)
	for line in taxon_f:
		line_sp = line.split('\t')
		taxs = line_sp[1].strip().split(';')
		taxs.append(line_sp[0])
		origin_tree.parse(taxs)
	return origin_tree


def get_level(tax_tree, level=1):
	level_tax = defaultdict(list)
	if level == 1:
		temp = dict([(i, [tax_tree._children[i]]) for i in tax_tree._children])
		return temp
		return tax_tree._children.keys()
	for i1 in tax_tree._children.values():
		if level == 2:
			for i in i1._children:
				level_tax[i].append(i1._children[i])
			continue
		for i2 in i1._children.values():
			if level == 3:
				for i in i2._children:
					level_tax[i].append(i2._children[i])
				continue
			for i3 in i2._children.values():
				if level == 4:
					for i in i3._children:
						level_tax[i].append(i3._children[i])
					continue
				for i4 in i3._children.values():
					if level == 5:
						for i in i4._children:
							level_tax[i].append(i4._children[i])
						continue
					for i5 in i4._children.values():
						if level == 6:
							for i in i5._children:
								level_tax[i].append(i5._children[i])
							continue
						for i6 in i5._children.values():
							if level == 7:
								for i in i6._children:
									level_tax[i].append(i6._children[i])
								continue
							for i7 in i6._children.values():
								for i in i7._children:
									level_tax[i].append(i7._children[i])
	return level_tax


def get_good_parent(child, origin):
	good_parent = child.get_good_parent()
	if good_parent:
		origin.new_name = origin.new_name + "_" + str(good_parent._name)
	else:
		origin.new_name = origin.new_name + "_" + 'None'
	if origin.new_name in check_dict:
		# get_good_parent(good_parent, origin)._name
		pass
	else:
		check_dict[origin.new_name] = 0
	return good_parent


def change_new_name(tree, level):
	for level, children in get_level(tree, level).iteritems():
		if len(children) > 1:
			for child in children:
				get_good_parent(child, child)


def change_all_name(tree):
	change_new_name(tree, 1)
	change_new_name(tree, 2)
	change_new_name(tree, 3)
	change_new_name(tree, 4)
	change_new_name(tree, 5)
	change_new_name(tree, 6)
	change_new_name(tree, 7)
	change_new_name(tree, 8)


def write_new(tree, fp):
	new_tax_file = open(fp, 'w')
	for one, ids in get_level(tree, 8).iteritems():
		for i in ids:
			new_tax = i.new_tax()
			for one_id in i.seq_id:
				new_tax_file.write(one_id + "\t" + new_tax + '\n')


if __name__ == "__main__":
	taxon_file = "Z:\\tmp_data\\test.tax"
	new_file = "Z:\\tmp_data\\test_new.tax"
	check_dict = {}
	# args = sys.argv[1:]
	# taxon_file = args[0]
	# new_file = args[1]
	mytree = parse_file(taxon_file)
	change_all_name(mytree)
	write_new(mytree, new_file)
