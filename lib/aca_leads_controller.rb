module LeadsControllerAutoCompleteAccounts
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :convert, :autocomplete
      alias_method_chain :promote, :autocomplete
    end
  end  

  module InstanceMethods
    def convert_with_autocomplete
      @lead        = Lead.my(@current_user).find(params[:id])
      @users       = User.except(@current_user).all
      @account     = Account.new(:user => @current_user, :name => @lead.company, :access => "Lead")
      @accounts    = []
      @opportunity = Opportunity.new(:user => @current_user, :access => "Lead", 
                                     :stage => "prospecting", :campaign => @lead.campaign, 
                                     :source => @lead.source)
      if params[:previous] =~ /(\d+)\z/
        @previous = Lead.my(@current_user).find($1)
      end

    rescue ActiveRecord::RecordNotFound
      @previous ||= $1.to_i
      respond_to_not_found(:js, :xml) unless @lead
    end

    def promote_with_autocomplete
      @lead  = Lead.my(@current_user).find(params[:id])
      @users = User.except(@current_user).all
      @account, @opportunity, @contact = @lead.promote(params)
      @accounts = []
      @stage = Setting.unroll(:opportunity_stage)

      respond_to do |format|
        if @account.errors.empty? && @opportunity.errors.empty? && @contact.errors.empty?
          @lead.convert
          update_sidebar
          format.js   # promote.js.rjs
          format.xml  { head :ok }
        else
          format.js   # promote.js.rjs
          format.xml  { 
            render( :xml => @account.errors + @opportunity.errors + @contact.errors, 
                    :status => :unprocessable_entity )
          }
        end
      end

    rescue ActiveRecord::RecordNotFound
      respond_to_not_found(:js, :xml)
    end
  end
end

LeadsController.send(:include, LeadsControllerAutoCompleteAccounts)
LeadsController.send(:auto_complete_for, :account, :name)
