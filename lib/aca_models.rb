module ContactAutoCompleteAccounts
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :update_with_account_and_permissions, :autocomplete
    end
  end  
  
  module InstanceMethods
    def update_with_account_and_permissions_with_autocomplete(params)
      unless params[:account][:name].blank?
        ## TODO this does not take into account whether the current_user is allowed to 
        ## TODO access the account.
        account = Account.find_by_name(params[:account][:name])
        params[:account][:id] = account.id unless account.nil?
      end
      update_with_account_and_permissions_without_autocomplete(params)
    end
  end
end

## Update the models
[Contact, Opportunity].each do |model|
  model.send(:include, ContactAutoCompleteAccounts)
end
