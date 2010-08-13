module OpportunitiesControllerAutoCompleteAccounts
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :edit, :autocomplete
      alias_method_chain :new, :autocomplete
      alias_method_chain :create, :autocomplete
    end
  end  

  module InstanceMethods
    def create_with_autocomplete
      unless params[:account][:name].blank?
        ## TODO this does not take into account whether the current_user is allowed to 
        ## TODO access the account.
        account = Account.find_by_name(params[:account][:name])
        params[:account][:id] = account.id if account
      end
      @opportunity = Opportunity.new(params[:opportunity])

      respond_to do |format|
        if @opportunity.save_with_account_and_permissions(params)
          if called_from_index_page?
            @opportunities = get_opportunities
            get_data_for_sidebar
          else
            get_data_for_sidebar(:campaign)
          end
          format.js   # create.js.rjs
          format.xml  { render :xml => @opportunity, :status => :created, :location => @opportunity }
        else
          @users = User.except(@current_user).all
          @accounts = []
          unless params[:account][:id].blank?
            @account = Account.find(params[:account][:id])
          else
            if request.referer =~ /\/accounts\/(.+)$/
              @account = Account.find($1) # related account
            else
              @account = Account.new(:user => @current_user)
            end
          end
          @contact = Contact.find(params[:contact]) unless params[:contact].blank?
          @campaign = Campaign.find(params[:campaign]) unless params[:campaign].blank?
          format.js   # create.js.rjs
          format.xml  { render :xml => @opportunity.errors, :status => :unprocessable_entity }
        end
      end
    end
    
    def new_with_autocomplete
      @opportunity = Opportunity.new(:user => @current_user, 
                                     :stage => "prospecting", 
                                     :access => Setting.default_access)
      @users       = User.except(@current_user).all
      @account     = Account.new(:user => @current_user)
      @accounts    = []
      if params[:related]
        model, id = params[:related].split("_")
        instance_variable_set("@#{model}", 
                              model.classify.constantize.my(@current_user).find(id))
      end

      respond_to do |format|
        format.js   # new.js.rjs
        format.xml  { render :xml => @opportunity }
      end

    rescue ActiveRecord::RecordNotFound # Kicks in if related asset was not found.
      respond_to_related_not_found(model, :js) if model
    end
    
    def edit_with_autocomplete
      @opportunity = Opportunity.my(@current_user).find(params[:id])
      @users = User.except(@current_user).all
      @account  = @opportunity.account || Account.new(:user => @current_user)
      ## set the @accounts only if there is a account set
      @accounts = unless @account.id.nil?
                    [Account.find(@account.id)]
                  else ; [] ; end
      if params[:previous] =~ /(\d+)\z/
        @previous = Opportunity.my(@current_user).find($1)
      end

    rescue ActiveRecord::RecordNotFound
      @previous ||= $1.to_i
      respond_to_not_found(:js) unless @opportunity
    end
  end
end

OpportunitiesController.send(:include, OpportunitiesControllerAutoCompleteAccounts)
OpportunitiesController.send(:auto_complete_for, :account, :name)
