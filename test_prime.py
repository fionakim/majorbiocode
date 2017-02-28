# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/20 14:03

import unittest
from prime import  is_prime
class PrimeTestCase(unittest.TestCase):
    '''

    '''
    def test_is_five_prime(self):
        '''

        :return:
        '''

        self.assertTrue(is_prime(5))

    def test_is_four_prime(self):
        '''

        :return:
        '''

        self.assertFalse(is_prime(4))

    def test_is_zero_prime(self):
        '''

        :return:
        '''

        self.assertFalse(is_prime(0))

    def test_negative_number(self):
        """Is a negative number correctly determined not to be prime?"""
        for index in range(-1, -10, -1):
            self.assertFalse(is_prime(index),msg='{} should not be determined to be prime'.format(index))

if __name__ == '__main__':
    unittest.main()
