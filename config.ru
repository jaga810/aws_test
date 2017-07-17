require 'active_record'
require 'rubygems'
require 'sinatra/base'
require 'mysql2'

ActiveRecord::Base.configurations = YAML.load_file('/home/ec2-user/app/database.yml')
#set :database_file, "/home/ec2-user/app/database.yml"
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['development'])

class Item < ActiveRecord::Base
end

class Sale < ActiveRecord::Base
end

class HelloApp < Sinatra::Base
    get '/' do
        'AMAZON'
    end

    get '/secret/' do
        protected!
        'SUCCESS'
    end

    get '/calc' do 
        num = params.keys[0].split(" ").join("+")
        res = ""
        begin
            res = eval num
        rescue NameError => ex
            res = "ERROR"
        end
        "#{res}"
    end

    get '/stocker' do
        function = params['function']
        res = ""
        case function 
        when 'addstock'
            res = addstock(params)
        when 'checkstock'
            res = checkstock(params)
        when 'sell'
            res = sell(params)
        when 'checksales'
            res = checksales
        when 'deleteall'
            res = deleteall
        else
            res = "ERROR"
        end

        "#{res}"
    end

    helpers do
        def addstock(params)
            amount = params['amount']
            amount ||= 1
            amount = amount.to_f

            name = params['name']

            return "ERROR" if  !is_amount?(amount) || name.nil?

            item = Item.find_by(name: name)
            if item.nil?
                Item.create(
                    :name => name,
                    :amount => amount
                )
            else
                item.update_attribute(:amount, item.amount+amount)
            end

            return ""
        end

        def checkstock(params)
            name = params['name']
            if name.nil?
                items = Item.all
            else
                item = Item.find_by(name: name)
                if item.nil?
                    return "ERROR"
                else
                    items = [item]
                end
            end

            res = ""
            for item in items
                res += "#{item.name}: #{item.amount}\n"
            end
            return res
        end

        def sell(params)
            name = params['name']

            amount = params['amount']
            amount ||= 1
            amount = amount.to_f

            price = params['price'].to_f

            item = Item.find_by(name:  name)

            return "ERROR" if name.nil? || !is_amount?(amount) || item.nil? || item.amount < amount || price < 0

            item.update_attribute(:amount, item.amount - amount)
            
            sale = Sale.first
            sale ||= Sale.create()

            sale.update_attribute(:amount , sale.amount + amount * price)
            return ""
        end

        def checksales
            sale = Sale.first
            sale ||= Sale.create()

            return "sales: #{sale.amount}"
        end

        def deleteall
            Sale.delete_all
            Item.delete_all
            return ""
        end

        def is_amount?(val)
            return val%1==0 && val>=0
        end


        def protected!
            unless authorized?
                response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
                throw(:halt, [401, "Not authorized\n"])
            end
        end
        def authorized?
            @auth ||= Rack::Auth::Basic::Request.new(request.env)
            @auth.provided? && @auth.basic? && @auth.credentials  == ['amazon', 'candidate']
        end
    end
end

run HelloApp
