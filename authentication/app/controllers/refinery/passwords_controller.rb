module ::Refinery
  class PasswordsController < ::Devise::PasswordsController
    layout 'login'

    skip_before_filter :find_pages_for_menu

    before_filter :store_password_reset_return_to, :only => [:update]
    def store_password_reset_return_to
      session[:'refinery_user_return_to'] = main_app.refinery_admin_root_path
    end
    protected :store_password_reset_return_to

    # Rather than overriding devise, it seems better to just apply the notice here.
    after_filter :give_notice, :only => [:update]
    def give_notice
      if %w(notice error alert).exclude?(flash.keys.map(&:to_s)) or @refinery_user.errors.any?
        flash[:notice] = t('successful', :scope => 'refinery.users.reset', :email => @refinery_user.email)
      end
    end
    protected :give_notice

    # GET /registrations/password/edit?reset_password_token=abcdef
    def edit
      if params[:reset_password_token] and (@refinery_user = User.where(:reset_password_token => params[:reset_password_token]).first).present?
        render_with_scope :edit
      else
        redirect_to(main_app.new_refinery_user_password_url, :flash => ({
          :error => t('code_invalid', :scope => 'refinery.users.reset')
        }))
      end
    end

    # POST /registrations/password
    def create
      if params[:refinery_user].present? and (email = params[:refinery_user][:email]).present? and
         (user = User.where(:email => email).first).present?

        # Call devise reset function.
        user.send(:generate_reset_password_token!)
        UserMailer.reset_notification(user, request).deliver
        redirect_to main_app.new_refinery_user_session_path, :notice => t('email_reset_sent', :scope => 'refinery.users.forgot') and return
      else
        @refinery_user = User.new(params[:refinery_user])
        flash.now[:error] = if @refinery_user.email.blank?
          t('blank_email', :scope => 'refinery.users.forgot')
        else
          t('email_not_associated_with_account_html', :email => @refinery_user.email, :scope => 'refinery.users.forgot').html_safe
        end
        render_with_scope :new
      end
    end
  end
end
