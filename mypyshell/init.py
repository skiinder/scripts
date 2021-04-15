#!/usr/bin/python
# -*- coding: UTF-8 -*-

import xml.etree.cElementTree as etree
import os
import sys
import xml.sax
import xml.dom.minidom

user = "atguigu"
env_file = "/etc/profile.d/my_env.sh"
source = "http://hadoop3.oss-cn-zhangjiakou-internal.aliyuncs.com/"
target = "/opt/module"


class Packages:
    def __init__(self, package, original_name, modified_name, add_env=true):
        self.__package = package
        self.__original_name = original_name
        self.__modified_name = modified_name
        self.__add_env = add_env

    def __init_env(self):
        lines = []
        try:
            lines = open(env_file, "r").readlines
            out = open(env_file, "w")
            for line in lines:
                if (self.__modified_name.upper + "_HOME") not in lines:
                    out.write(line)
            out.close
        except Exception as e:
            pass
        out = open(env_file, "a")
        out.write("#" + self.__modified_name.upper + "_HOME\n")
        out.write(self.__modified_name.upper + "_HOME="  +target + "/" + self.__modified_name)
        out.write("#"+self.__modified_name.upper+"_HOME\n")


class Properties:
    def __init__(self, file):
        global pro_file
        self.__pros = {}
        self.__source = file
        try:
            pro_file = open(self.__source, 'r')
            for line in pro_file:
                if line.find('=') > 0:
                    s = line.replace('\n', '').split("=")
                    self.__pros[s[0]] = s[1]
        except Exception as e:
            pass

    def __getitem__(self, item):
        return self.__pros.get(item)

    def __setitem__(self, key, value):
        self.__pros[key] = value

    def save(self):
        global pro_file
        try:
            pro_file = open(self.__source, 'w')
            for key, value in self.__pros.items():
                pro_file.writelines(key + "=" + value + "\n")
        finally:
            pro_file.close()


class Configuration:
    def __init__(self, file):
        self.__source = file
        self.__pros = {}
        try:
            doc = etree.parse(file).getroot()
            for item in doc.findall("property"):
                self.__pros[item.find("name").text] = item.find("value").text
        except Exception as e:
            pass

    def __getitem__(self, item):
        return self.__pros.get(item)

    def __setitem__(self, key, value):
        self.__pros[key] = value

    def save(self):
        doc = xml.dom.minidom.Document()
        pi = doc.createProcessingInstruction(
            'xml-stylesheet', 'type="text/xsl" href="configuration.xsl"')
        root = doc.createElement("configuration")
        doc.appendChild(root)
        for name, value in self.__pros.items():
            props = doc.createElement("property")
            name_node = doc.createElement("name")
            name_node.appendChild(doc.createTextNode(name))
            value_node = doc.createElement("value")
            value_node.appendChild(doc.createTextNode(value))
            props.appendChild(name_node)
            props.appendChild(value_node)
            root.appendChild(props)
        doc.insertBefore(pi, root)
        doc.writexml(open(self.__source, 'w'), indent='',
                     addindent='    ', newl='\n', encoding="utf-8")
