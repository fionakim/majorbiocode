# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/20 13:58

def is_prime(number):
    '''

    :param number:
    :return:
    '''
    if number < 2:
        return False
    for e in range(2,number):
        if number%e == 0:
            return False
    return True

def print_next_prime(number):
    '''
    :param number:
    :return:
    '''

    index = number
    while True:
        index += 1
        if is_prime(index):
            print index



