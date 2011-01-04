#GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Zabbix CLI Tool and associated files
#Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

##########################################
# Subversion information
# $Id$
# $Revision$
##########################################

require 'libs/zdebug'

require 'pp'
require 'rexml/document'

# CommandHelp is the class which behaves as a wrapper to the help text stored in a separate file.
# All help functions are dynamically generated by default.  This is done through the lambda procedure
# in the method "method".  The overloaded method "method" attempts to determine if the symbol passed
# in matches a pre-existing method.  If it does not a local default lambda is created and returned.
class CommandHelp

  include ZDebug

  def initialize(language)
    @file = File.new("libs/help.xml")

    @doc=REXML::Document.new(@file).elements["//help[@language='#{language}']"]
#    puts @doc.root.attributes
   
    EnvVars.instance.register_notifier("language",self.method(:language=))
  end

  def language=(language)
    @file.rewind
    @doc=REXML::Document.new(@file).elements["//help[@language='#{language}']"]
  end

  alias o_method method

  # This overloaded method returns a local lambda if the symbol passed in is not found
  # The lambda behaves as a default help function looking up the passed in symbol in the help file
  # If the command is found but no help exists, a message stating this is printed
  def method(sym)
    debug(8,sym,"CommandHelp.method overload (sym)")
    methods=self.methods
    index=methods.index(sym.to_s)
    if !index.nil?
      method_local=o_method(sym)
    else
      method_local=lambda do |not_used|  #not_used is here due to zabcon_globals and callbacks. 
        debug(6, sym, "auto generated help func for")
        item=@doc.elements["//item[@command='#{sym.to_s}']"]
        if item.nil?
          puts "Help not available for internal command: #{sym.to_s}"
	      else
	        puts item.text
	      end
      end
    end
    debug(8,method_local,"returning")
    method_local
  end

  def help(command_tree,input)
    input=input.gsub(/^\s*help\s*/,"")  #strip out the help statement at the start
    debug(6,command_tree.commands,"command_tree",350)
    debug(6,input,"input")

    items=input.split(" ")
    if items.length==0
      puts @doc.elements["//item[@command='help']"].text
    else # more than "help" was typed by the user
      help_cmd=items.join(" ").lstrip.chomp

      if help_cmd.downcase=="commands"
        puts @doc.elements["//item[@command='help_commands']"].text
      else
        debug(4,help_cmd,"Searching for help on")

        cmd=command_tree.search(help_cmd)[0]  #search returns an array
        if cmd.nil? or cmd[:helpproc].nil?
          puts "Unable to find help for \"#{help_cmd}\""
        else
          cmd[:helpproc].call(nil)  #TODO: need to fix, see line 67 above
        end
      end
    end
  end  #def help
end
