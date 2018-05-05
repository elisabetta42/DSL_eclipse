/*
 * generated by Xtext 2.12.0
 */
package org.xtext.example.mydsl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.example.mydsl.myDsl.Simulation
import org.xtext.example.mydsl.myDsl.Roles
import org.xtext.example.mydsl.myDsl.Rules
import org.xtext.example.mydsl.myDsl.Behaviors
import org.xtext.example.mydsl.myDsl.Assignment
import org.xtext.example.mydsl.myDsl.Statements
import org.xtext.example.mydsl.myDsl.Method
import org.xtext.example.mydsl.myDsl.ConditionExp
import org.xtext.example.mydsl.myDsl.M_List
import org.xtext.example.mydsl.myDsl.Variable
import org.xtext.example.mydsl.myDsl.Loop
import org.xtext.example.mydsl.myDsl.M_Number
import org.xtext.example.mydsl.myDsl.M_Float
import org.xtext.example.mydsl.myDsl.PlusOp
import org.xtext.example.mydsl.myDsl.MinusOp
import org.xtext.example.mydsl.myDsl.DivOp
import org.xtext.example.mydsl.myDsl.MultOp
import org.xtext.example.mydsl.myDsl.ReturnValue
import org.xtext.example.mydsl.myDsl.MethodEmpty
import org.xtext.example.mydsl.myDsl.SetVelocity
import org.xtext.example.mydsl.myDsl.OrOp
import org.xtext.example.mydsl.myDsl.AndOp
import org.xtext.example.mydsl.myDsl.Equality
import org.xtext.example.mydsl.myDsl.NotEquality
import org.xtext.example.mydsl.myDsl.GreaterOp
import org.xtext.example.mydsl.myDsl.LowerOp
import org.xtext.example.mydsl.myDsl.GreaterEqOp
import org.xtext.example.mydsl.myDsl.LowerEqOp
import org.xtext.example.mydsl.myDsl.Condition
import org.xtext.example.mydsl.myDsl.Conditional_Statement
import org.xtext.example.mydsl.myDsl.Sequences
import org.xtext.example.mydsl.myDsl.States
import org.xtext.example.mydsl.myDsl.Propagate
import org.xtext.example.mydsl.myDsl.Negative_Number
import org.xtext.example.mydsl.myDsl.Ensemble
import java.util.ArrayList
import org.xtext.example.mydsl.myDsl.Wait
import org.xtext.example.mydsl.myDsl.Normalize
import org.xtext.example.mydsl.myDsl.Move
import org.xtext.example.mydsl.myDsl.List_Index
import org.xtext.example.mydsl.myDsl.Shared_Variable
import org.xtext.example.mydsl.myDsl.Share_Variable
import org.xtext.example.mydsl.myDsl.SetUnion
import org.xtext.example.mydsl.myDsl.MaxMethod
import org.xtext.example.mydsl.myDsl.Method_Two

//import org.xtext.example.mydsl.myDsl.Conditional_Statement

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MyDslGenerator extends AbstractGenerator {
	
String s="	"
ArrayList<Roles> roles = new ArrayList<Roles>()
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		
		roles.clear
		val simulation2= resource.allContents
			.filter(typeof(Simulation)).next
		resource.allContents
			.filter(typeof(Sequences)).forEach[generateSequenceFile(resource,simulation2,fsa)];
		resource.allContents
			.filter(typeof(Ensemble)).forEach[generateEnsembleFile(resource,fsa)];
		
		resource.allContents
			.filter(typeof(Roles)).forEach[addRole(resource,fsa)];
			
		resource.allContents
			.filter(typeof(Simulation)).forEach[generateSimulationFile(resource,fsa)];
					
	}
	def generateEnsembleFile(Ensemble e,Resource resource,IFileSystemAccess2 fsa) {
		fsa.generateFile(e.name+".py",e.generateEnsemble());
	}
	def addRole(Roles r,Resource resource,IFileSystemAccess2 fsa){
		roles.add(r)
	}
	def generateSimulationFile(Simulation s,Resource resource,IFileSystemAccess2 fsa) {
		fsa.generateFile(s.name+".py",s.generateSim());
	}
	
	def generateSequenceFile(Sequences s,Resource resource, Simulation sim, IFileSystemAccess2 fsa) {
		fsa.generateFile(s.name+".py",s.generateSequence(sim));
	}
	def CharSequence generateEnsemble(Ensemble e)''' 
		import plugin
		import math
		
		class «e.name.toFirstUpper()»:
		 ensemble=None
		 agents=None
		 name=None
		 drone_id=None
		 def __init__(self,agents,name):
			self.agents=agents
			self.ensemble=[]
			self.drone_id=[]	
		 	
		 def register_member(self,drone):
			for d in self.ensemble:
				if drone.tag==d.tag:
					return
			if (drone.temperature_sensor==True):
				self.ensemble.append(drone)
			if (drone.water_cargo==True):
				self.ensemble.append(drone)	
		 def delete_member(self): #delete after timeout
		        print "hola"
		 def synchronize_state(self,current):
			  n_list=[]
			  self.register_member(current)
			  print "synchronizing...........",current.tag
			  for d in self.agents:
				if d.heartbeat(current,100)== True:
					n_list.append(d);
		          #print (n_list), "printing len of n_list"
			  for uav in n_list:
				self.register_member(uav)	  
			  for drone in self.ensemble:	
				#make them execute their state
				if drone.tag!=current.tag:
					current.stat_m.receive_message(drone.stat_m.send_message()) #current receives from everyone in the ensemble
					drone.stat_m.receive_message(current.stat_m.send_message()) #current sends state to everyone in the ensemble
			  #if current.role==current.stat_m.send_message().role:
		          current.stat_m.execute(current.stat_m.send_message())
			  for drone in self.ensemble:	
			  	if self.get_state_from_other(drone)==True and drone.stat_m.send_message().name==current.stat_m.send_message().name:			
					count=self.check_others_state(current,drone,current.stat_m.send_message())		
			  		print "I am increasing the counter",count	
			  self.initiate(n_list,current)
		 «FOR stat :e.statements»«stat.generateAssignment()»«ENDFOR»
		 def distance(self,old,new):
		 	distance=math.sqrt(pow((old[0] - new[0]), 2) + pow((old[1] - new[1]), 2))#+ pow((z1 - z2), 2))
		  	return distance
		 def not_found(self,fire,new):
		 		for point in fire:
		 			if abs(point[0]-new[0])<=1 and abs(point[1]-new[1])<=1:
		 				return False
		 		return True
		 def check_others_state(self,current,drone,state):
		 	if current.role==drone.role: #and current.stat_m.send_message()==drone.stat_m.send_message:
		 		print "I am in if inside check"
		 		for d in state.drone_id:
		 			if d==drone.tag:
		 				return len(state.drone_id)
		 		state.drone_id.append(drone.tag)
		 	#print "len of drone list: ",  len(self.drone_id)
		 	return len(state.drone_id)
		  
		 def get_state_from_other(self,drone):
		 	return drone.stat_m.send_message().complete
		 def state_changed(self,drone):
		 	drone.ensemble.count=0
		 	del drone.ensemble.drone_id[:]
		  
	'''	
	def CharSequence generateSim(Simulation sim)'''
		#!/usr/bin/env python
		from pvector import PVector
		import numpy
		import math
		import temperature_function as temp
		#import plugin
		import time
		from random import randint	
		def sub_all_x(close_drones, current):
			dx=0
			for other in close_drones:
				dx-=current.xyz[0]-other.xyz[0]
			return dx
								
		def sub_all_y(close_drones, current):
			dy=0
			for other in close_drones:
				dy-=current.xyz[1]-other.xyz[1]
			return dy
		def sum_all_x(close_drones, current):
			dx=0
			for other in close_drones:
				dx+=other.xyz[0]
			return dx
								
		def sum_all_y(close_drones, current):
			dy=0
			for other in close_drones:
				dy+=other.xyz[1]
			return dy
				
		def sum_all_vel_x(close_drones, current):
			dx=0
			for other in close_drones:
				dx+=other.v_ned_d[0]
			return dx
								
		def sum_all_vel_y(close_drones, current):
			dy=0
			for other in close_drones:
				dy+=other.v_ned_d[1]
			return dy
				
		def find_neighbours_in_radius(current,radius):
			agents=current.group.all_drones
			neibourgh=[]
			for it in agents:
				if euclidean_distance(it.xyz,current.xyz)<=radius and it.role==current.role:
					neibourgh.append(it)
			return neibourgh
				
		def euclidean_distance(a,b):
			distance=math.sqrt(pow((a[0] - b[0]), 2) + pow((a[1] - b[1]), 2))
			return distance
		def stay_in_border(position):
			v=PVector(0,0)
			Xmin=13
			Xmax=13
			Ymin=13
			Ymax=13
			constant=100
			if position.x <= Xmin:
				v.x = constant
			elif position.x >= Xmax:
				v.x = -constant
				
			if position.y <= Ymin :
				v.y = constant
			elif position.y >= Ymax :
				v.y = -constant
				
			return v.return_as_vector()
		def get_coordinates(current):
			return current.xyz[0:1]
		def normalize(vector):
			vector=PVector(vector[0],vector[1])
			vector.normalize()
			return vector.return_as_vector()
		def temperature_sensor(current):
			fire_x=0.0
			fire_y=0.0
			value=[]
			a=10000
			b=6
			distance=math.sqrt(pow((current.xyz[0] - fire_x), 2) + pow((current.xyz[1] - fire_y), 2))
			temperature=a/(distance+b)
			value.append(temperature)
			return temperature
		
		def get_position_by_radius(current):
			x=float("{0:.2f}".format(current.xyz[0]))	
			y=float("{0:.2f}".format(current.xyz[1]))
			position=numpy.array([x,y])
			for point in current.var:
				print "pointsssss",position,point
				if abs(point[0]-position[0])<=1 and abs(point[1]-position[1])<=1:
					return current.var       		
			current.var.append(position)
			return current.var
			
			
		«FOR elem :sim.elements»
				«elem.generateElement()»
		«ENDFOR»	
	'''
	
	def dispatch CharSequence generateElement(Roles r)'''
		«r.generateRole()»
	'''
	
	def  CharSequence generateCheck(Roles r)'''
	«IF r.condition!=null»
		if «r.condition.condition.generateExp()»:
			current.role="«r.name»"
	«ENDIF»
	'''
	
	def dispatch CharSequence generateElement(Sequences seq)'''
	def assign_role(current):
		«FOR role : roles»
			«role.generateCheck()»
		«ENDFOR»
	'''
	def dispatch CharSequence generateElement(Ensemble es)''''''
	
	def CharSequence generateSequence(Sequences r,Simulation sim)'''
	#!/usr/bin/env python
	from state import State 
	from transition import Transition 
	from condition import Condition 
	import «sim.name»
	import time
	
	class StateMachine:
	 states=None
	 initial_state=None
	 last_state=None
	 current_state=None
	 current=None
	 count=1
	 flag=None
	 def __init__(self,current):
		self.states=[]
	 	self.current=current
	 	self.build()
		self.flag=False
	 def create_initial_state(self,name, role, action_method,condition):
		state=State(name,role,action_method,self.current,condition)
		self.initial_state=state
		self.last_state=state
		self.current_state=self.initial_state
		#print "state ",self.count,state.name
		self.count=self.count+1
		self.states.append(state)
		return self
	 	
	 def create_state(self,name, role, action_method,condition):
		state=State(name,role,action_method,self.current,condition)
		self.last_state.next=state
		self.last_state=state
		#print "state ",self.count,state.name
		self.count=self.count+1
		self.states.append(state)
		return self
	 
	 def receive_message(self,new_state):
		 if self.current_state.next!=None:
		 	self.update_state(new_state,self.current_state.next)
			
	
	 def update_state(self,new_state,current_state):
		if current_state==None:
			return 
		elif current_state.name==new_state.name:
			self.current_state=current_state
			return
		elif(current_state.next!=None): self.update_state(new_state,current_state.next)
			
	 def execute(self, state):	
		if self.current_state.next!=None  and len(state.drone_id)==state.condition.max_count:
			 self.current_state=self.current_state.next
		state.execute()
	 def trigger_state_change(self,state):
		if state!=self.current_state:
			return True
		else: return False
				
	 def send_message(self):
		return self.current_state
	
	 def print_states(self,state):
		print "current state= ",state.name
		if state.next==None:
			return
		self.print_states(state.next)
	 
	 def build(self):
      self.«FOR i :1..r.states.size SEPARATOR '.'»«IF(i==1)»«r.states.get(i-1).generate_Initial_State(sim)»«ELSE »«r.states.get(i-1).generateState(sim)»«ENDIF»«ENDFOR»
	'''
	
	def CharSequence generateState(States state,Simulation sim)'''
	create_state("«state.state_name»","«state.role_name»",«sim.name».«state.action_name»,Condition(3,0))'''
	
	
	def CharSequence generate_Initial_State(States state,Simulation sim)'''
	create_initial_state("«state.state_name»","«state.role_name»",«sim.name».«state.action_name»,Condition(3,0))'''
	
	def generateRoleFile(Roles role,Resource resource,Simulation sim,IFileSystemAccess2 fsa){
		fsa.generateFile(role.name+".py",role.generateRole());
	}
	
	def CharSequence generateRole(Roles r)'''
	«FOR member :r.members»
		«member.generateMember(r.condition)»
	«ENDFOR»
	'''
	def dispatch CharSequence generateMember(Rules rule,Condition c)'''
	
	def «rule.name» (current):
		alt_d=8
		position=PVector(current.xyz[0],current.xyz[1])
	«FOR stats :rule.statements»
			«stats.generateStatement()»
	«ENDFOR»		
	'''
	def CharSequence generateStatement(Statements stats)	
	'''	«stats.generateAssignment()»'''
	def dispatch CharSequence generateAssignment(Assignment ass)
	'''«ass.right.name»=«ass.left.generateLeft()»«ass.check_if()»'''
	
	def CharSequence check_if(Assignment ass)'''
	«IF(contains(ass.left.generateLeft().toString(),"find_neighbours_in_radius")==true)»
	if len(«ass.right.name»)==0:
		empty=PVector(0,0)
		velocity=PVector(current.v_ned_d[0],current.v_ned_d[1])
		current.set_v_2D_alt_lya(velocity.return_as_vector(),-alt_d)
		return empty.return_as_vector()
	«ENDIF»
	'''
	def dispatch CharSequence generateAssignment(Propagate prop)''' '''
	def dispatch CharSequence generateAssignment(Shared_Variable variable)'''
	current.shared_variable(«variable.variable.generateExp()»,"«variable.variable.generateExp()»")
	'''
	def dispatch CharSequence generateAssignment(Share_Variable variable)'''
	def merge(self,«variable.element.generateExp()»,other_«variable.element.generateExp()»):
		for old in «variable.element.generateExp()»:
			for new in other_«variable.element.generateExp()»:
				self.«variable.method.st.generate_call(variable.element)»	
	«variable.method.st.generate_method(variable.element)»
	def initiate(self,n_list,current):
		for other in n_list:
				if other.tag!=current.tag:
					if len(other.var)==0 and len(current.var)!=0:
						other.shared_variable(current.var,"«variable.element.generateExp()»")
		
					if len(other.var)!=0 and len(current.var)==0:
						print "I am in case 2"
						current.shared_variable(other.var,"«variable.element.generateExp()»")
		
					if len(other.var)!=0 and len(current.var)!=0:
						print "I am in case 3"
					        self.merge(current.variables["«variable.element.generateExp()»"],other.variables["«variable.element.generateExp()»"])
		
		n_list[:] = []
		
		
	'''
	def dispatch CharSequence generate_call(SetUnion set, Variable v)'''
	set_union(«v.generateExp()»,new,old)
	'''
	def dispatch CharSequence generate_call(MaxMethod max, Variable v)''''''
	
	def dispatch CharSequence generate_method(SetUnion set, Variable v)''' 
	def set_union(self,«v.generateExp()»,new,old):
		if «set.lamba.comp.generateExp()»:
		«s»«v.generateExp()».append(new)	'''
	
	def dispatch CharSequence generate_method(MaxMethod max,Variable v)''' '''
	
	def dispatch CharSequence generateAssignment(ReturnValue ret)'''
	return «ret.result.generateExp()»
	'''
	def dispatch CharSequence generateAssignment(Move mov)'''
	«mov.point.generateExp()»_v=«mov.point.generateExp()»(current)
	alt_d=8
	current.set_v_2D_alt_lya(«mov.point.generateExp()»_v,-alt_d)
	'''
	def dispatch CharSequence generateAssignment(SetVelocity set)'''
	alt_d=8
	current.set_v_2D_alt_lya(«set.variable.name»,-alt_d)
	'''
	def dispatch CharSequence generateAssignment(Wait wait)'''
	current.set_xyz_ned_lya(current.xyz)
	'''
	def dispatch CharSequence generateAssignment(Normalize norm)'''
	«norm.vector.generateExp()»=normalize(«norm.vector.generateExp()»)
	'''
	def dispatch CharSequence generateAssignment(Conditional_Statement con)'''
	if «con.condition.generateExp()»:
		«FOR stat: con.if_stats»
		«stat.generateAssignment()»
		«ENDFOR »
	'''
	
	def dispatch CharSequence generateCondition(Condition con)
	'''	if not«con.condition.generateExp()»:
		 current.set_xyz_ned_lya(current.xyz)
		 return
	'''
	
	def dispatch CharSequence generateMember(Behaviors behavior,Condition c)'''
	def «behavior.name» (current):
		print "«behavior.name»" 
	«IF c!=null»
	«c.generateCondition()»
	«ENDIF»
	«FOR stats :behavior.statements»
			«stats.generateStatement()»
	«ENDFOR»				
	'''
	def dispatch CharSequence generateLeft(M_List list)''' 
	numpy.array([«list.x.generateExp()»,«list.y.generateExp()»])
	'''
	def dispatch CharSequence generateLeft(ConditionExp exp)'''«exp.generateExp()»'''
		
	def dispatch CharSequence generateExp(Method met)'''«met.name»(«met.argument.generateArgument()»)'''
	def dispatch CharSequence generateExp(MethodEmpty met)'''«met.name»(current)'''
	def dispatch CharSequence generateExp(Method_Two met)'''self.«met.name»(«met.argument1.generateExp()»,«met.argument2.generateExp()»)'''
	def dispatch CharSequence generateArgument(M_Number numb)'''current,«numb.digit»'''
	def dispatch CharSequence generateArgument(M_Float float_num)''' '''
	def dispatch CharSequence generateArgument(Variable variable)''' '''
	def dispatch CharSequence generateArgument(Loop loop)'''
	«loop.list»,current'''
	
	
	def dispatch CharSequence generateExp(OrOp pop) '''(«pop.left.generateExp» or «pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(AndOp pop) '''(«pop.left.generateExp» and «pop.right.generateExp»)'''
	
	def dispatch CharSequence generateExp(Equality pop) '''(«pop.left.generateExp»==«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(NotEquality pop) '''(«pop.left.generateExp»!=«pop.right.generateExp»)'''
	
	def dispatch CharSequence generateExp(GreaterOp pop) '''(«pop.left.generateExp»>«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(LowerOp pop) '''(«pop.left.generateExp»<«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(GreaterEqOp pop) '''(«pop.left.generateExp»>=«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(LowerEqOp pop) '''(«pop.left.generateExp»<=«pop.right.generateExp»)'''
	
	def dispatch CharSequence generateExp(PlusOp pop) '''(«pop.left.generateExp»+«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(MinusOp pop) '''(«pop.left.generateExp»-«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(DivOp pop) '''(«pop.left.generateExp»/«pop.right.generateExp»)'''
	def dispatch CharSequence generateExp(MultOp mop) '''(«mop.left.generateExp»*«mop.right.generateExp»)'''
	
	def dispatch CharSequence generateExp(M_Number number) '''«number.digit»'''
	def dispatch CharSequence generateExp(Negative_Number number) '''-«number.numb»'''
	def dispatch CharSequence generateExp(M_Float number) ''''''
	def dispatch CharSequence generateExp(List_Index index) '''   
	«index.prefix.generateExp()»[«index.index.generateExp()»]'''
	def dispatch CharSequence generateExp(Variable variable)'''
	«IF(isNull(variable.suffix)==false &&  variable.suffix=="length")»len(«variable.name»)«ENDIF»«IF(isNull(variable.suffix)==false && variable.suffix!="length")»«variable.name».«variable.suffix»«ENDIF»«IF isNull(variable.suffix)==true»«variable.name»«ENDIF»'''
	
	def isNull(String s){
		if (s==null) {
			return true
		}
		else return false
		
	}
	
	def contains(String one,String two){
		if(one.contains(two)==true){
			return true
			}
		else return false
		}
	}

