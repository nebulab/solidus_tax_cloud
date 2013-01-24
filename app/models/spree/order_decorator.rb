require_relative 'tax_cloud/tax_cloud_transaction'

Spree::Order.class_eval do

   has_one :tax_cloud_transaction


   self.state_machine.after_transition :to => :payment,
					      :do => :lookup_tax_cloud,
					      :if => :tax_cloud_eligible?
  
   self.state_machine.after_transition :to => :complete,
					     :do => :capture_tax_cloud,
					     :if => :tax_cloud_eligible?


   def tax_cloud_eligible?

       ship_address.try(:state_id?)

   end


   def lookup_tax_cloud

      unless tax_cloud_transaction.nil?

	tax_cloud_transaction.lookup

	Spree::Adjustment.where("originator_id = ?", tax_cloud_transaction.id)

	puts "In tax_cloud_existing: #{order.promotion}"

	 unless adjustments.promotion.blank?

	       # matched_line_items = line_items.select do |line_item|
		    # line_item.product.tax_category == rate.tax_category
	       # end

	       line_items_total = line_items.map.sum(&:total) 
	       
	       promo_rate = tax_cloud_transaction.amount / line_items_total
	       
	       adjusted_total = line_items_total + self.promotions_total 

	       adjustment.amount = order.line_items.empty? ? 0 : adjusted_total * promo_rate
	end 


      else

	 create_tax_cloud_transaction

	 tax_cloud_transaction.lookup

	 adjustments.create do |adjustment|

	    adjustment.source = self

	    adjustment.originator = tax_cloud_transaction

	    adjustment.label = 'Tax'

	    adjustment.mandatory = true

	    adjustment.eligible = true

	    puts "In spree_tax_cloud, adjustments."

	    unless adjustments.promotion.blank?

	       # matched_line_items = line_items.select do |line_item|
		    # line_item.product.tax_category == rate.tax_category
	       # end

	       line_items_total = line_items.map.sum(&:total) 
	       
	       promo_rate = tax_cloud_transaction.amount / line_items_total
	       
	       adjusted_total = line_items_total + promotions_total 

	       adjustment.amount = order.line_items.empty? ? 0 : adjusted_total * promo_rate

	    else

	       adjustment.amount = tax_cloud_transaction.amount
	    
	    end

	 end

      end

   end

 

   def capture_tax_cloud

      return unless tax_cloud_transaction

      tax_cloud_transaction.capture

   end

end
