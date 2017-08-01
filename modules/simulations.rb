module Simulations
	attr_accessor :sim_parent, :sim_child, :sim_id
	def sim_master
		if self.sim_parent
			return self.sim_parent.sim_master
		else
			return self
		end
	end
	def sim_master_id
		self.sim_master.sim_id
	end
	def same_sim?(other_object)
		other_object.sim_id == self.sim_id
	end
	def same_master?(other_object)
		self.sim_master_id == other_object.sim_master_id
	end
end
