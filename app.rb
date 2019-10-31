require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'bcrypt'
require 'aws-sdk'
require 'tmpdir'

enable :sessions

class Product < ActiveRecord::Base
end

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 50 }  
  validates :email, presence: true, length: { maximum: 255 }, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }, uniqueness: { case_sensitive: false }
  has_secure_password
end

get '/' do
  @title = 'トップページ'
  @products = Product.all #eachのproductへ
  erb :'index'
end

get '/upload' do
  @title = '投稿画面'
  erb :'upload'
end

post '/products' do
  
  file = params[:image][:tempfile]
  
  Aws.config.update({
    credentials: Aws::Credentials.new(
      ENV['AWS_S3_ACCESS_KEY_ID'],
      ENV['AWS_S3_SERECT_ACCESS_KEY'],
      )
  })
  s3 = Aws::S3::Resource.new(region: 'ap-northeast-1')
  name = File.basename(file)

  obj = s3.bucket(ENV['AWS_S3_BUCKET_NAME']).object(name)

  obj.upload_file(file)

  bucket_name = ENV['AWS_S3_BUCKET_NAME']
  image_url = "https://#{bucket_name}.s3-ap-northeast-1.amazonaws.com/#{name}"
  product_params = { title: params[:title], desc: params[:desc], image: image_url}  
  product = Product.new(product_params)

  if product.save!
    redirect '/'
  else
    redirect '/upload'
  end
end

get '/:id/product_edit' do
  @title = '編集画面'
  @product = Product.find(params[:id])
  erb :'product_edit'
end

put '/:id' do
  product_params = { title: params[:title], desc: params[:desc] }
  product = Product.find(params[:id])
  
  if product.update!(product_params)
    redirect '/'
  else
    redirect "/#{params[:id]}/product_edit"
  end
end

delete '/:id' do
  product = Product.find(params[:id])
  product.destroy!
  redirect "/"
end

get '/sign_up' do
  @title = 'アカウント作成'
  
  session[:user_id] ||= nil
  if session[:user_id]
    redirect '/log_out'
  end
  
  erb :'sign_up'
end

post '/sign_up' do
  user_params = { email: params[:email], name: params[:name], password: params[:password]}
  
  user = User.new(user_params)
  if user.save!
    session[:user_id] = user.id
    redirect '/'
  else
    redirect '/sign_up'
  end
end

get '/log_in' do
  @title = 'ログイン'
  
  if session[:user_id]
    redirect '/'
  end

  erb :'log_in'
end

post '/log_in' do
  user = User.find_by(email: params[:email])
  
  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect '/'
  else
    redirect "/log_in"
  end
end

post '/log_out' do
  session.clear
  redirect '/log_in'
end

# get '/user' do
#   @title = 'ユーザーページ'
#   @user = User.find(params[:id])
#   erb :'user'
# end

# get "/:id/user_edit" do
#   @user = User.find_by(id: params[:id])
#   erb :'user/user_edit'
# end

# put '/:id' do
#   user_params = { name: params[:name], bio: params[:bio], email: params[:email], password: params[:password]}
#   user = User.find(params[:id])
#   if user.update!(user_params)
#     redirect '/user'
#   else
#     redirect "/#{params[:id]}/user_edit"
#   end
# end

configure do
  set :server, :puma
end
