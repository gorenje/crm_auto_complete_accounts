module ContactsControllerAutoCompleteAccounts
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :create, :autocomplete
      alias_method_chain :edit,   :autocomplete
      alias_method_chain :new,    :autocomplete
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

      @contact = Contact.new(params[:contact])

      respond_to do |format|
        if @contact.save_with_account_and_permissions(params)
          @contacts = get_contacts if called_from_index_page?
          format.js   # create.js.rjs
          format.xml  { render :xml => @contact, :status => :created, :location => @contact }
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
          @opportunity = Opportunity.
            find(params[:opportunity]) unless params[:opportunity].blank?
          format.js   # create.js.rjs
          format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
        end
      end
    end

    def new_with_autocomplete
      @contact  = Contact.new(:user => @current_user, :access => Setting.default_access)
      @account  = Account.new(:user => @current_user)
      @users    = User.except(@current_user).all
      @accounts = []
      if params[:related]
        model, id = params[:related].split("_")
        instance_variable_set("@#{model}", model.classify.constantize.my(@current_user).find(id))
      end

      respond_to do |format|
        format.js   # new.js.rjs
        format.xml  { render :xml => @contact }
      end

    rescue ActiveRecord::RecordNotFound # Kicks in if related asset was not found.
      respond_to_related_not_found(model, :js) if model
    end
    
    def edit_with_autocomplete
      @contact  = Contact.my(@current_user).find(params[:id])
      @users    = User.except(@current_user).all
      @account  = @contact.account || Account.new(:user => @current_user)
      ## set the @accounts only if there is a account set
      @accounts = unless @account.id.nil?
                    [Account.find(@account.id)]
                  else ; [] ; end
      if params[:previous] =~ /(\d+)\z/
        @previous = Contact.my(@current_user).find($1)
      end

    rescue ActiveRecord::RecordNotFound
      @previous ||= $1.to_i
      respond_to_not_found(:js) unless @contact
    end
  end
end

ContactsController.send(:include, ContactsControllerAutoCompleteAccounts)
ContactsController.send(:auto_complete_for, :account, :name)
