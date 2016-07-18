require 'json'
require(File.join(File.expand_path(File.dirname(__FILE__)), 'ldap'))

module UI
  class User < Thor

    desc 'all', 'get all users'
    method_option :save_as_json, type: :boolean, default: false,
                                 aliases: '-j', desc: 'List of users'
    def all
      ctr = LdapController.new
      users = ctr.users
      users[:list_of_users] = valid_users users[:list_of_users]
      users_graph = users[:list_of_users]
        .collect { |u| u[:physicaldeliveryofficename] || 'Unknown' }
        .inject(Hash.new(0)) { |total, e| total[e] += 1 ;total }
      all_users = []
      real_graph = []
      users_graph.each do |k,v|
        real_graph.push(
          key: k,
          y: v
        )
        all_users.push({
          key: k,
          count: v,
          users: get_users_from(users[:list_of_users], k)
          })
      end
      if options[:save_as_json]
        write_report('reports/graph.json', real_graph.to_json)
        write_report('reports/users.json', JSON.pretty_generate(all_users))
      else
        puts "\n #{Hirb::Helpers::Table.render users[:list_of_users], hirb_options_for_user} \n".green
      end
    end

    private

    def write_report(path, contents)
      puts "Writing #{path}"
      File.write(path, contents)
    end

    def get_users_from(users, key)
      rez = []
      users.each do |user|
        if user[:physicaldeliveryofficename] == key
          rez.push({
            name: user[:name],
            mail: user[:mail],
            telephonenumber: user[:telephonenumber]
            })
        else
          if !user[:physicaldeliveryofficename] && key == "Unknown"
            rez.push({
              name: user[:name],
              mail: user[:mail],
              telephonenumber: user[:telephonenumber]
            })
          end
        end
      end
      rez
    end

    def valid_users users
      rez = []
      towns = ['Cluj-Napoca', 'Deva', 'Oradea', 'Unknown']
      users.each do |user|
        if !user[:physicaldeliveryofficename] || towns.include?(user[:physicaldeliveryofficename])
          rez.push user
        end
      end
      rez
    end

    def hirb_options_for_user
      {
        headers: {
          name: 'Name',
          mail: 'Mail',
          physicaldeliveryofficename: 'Locality',
          telephonenumber: "Telephone"
        },
        fields: [:name, :mail, :physicaldeliveryofficename, :telephonenumber]
      }
    end

  end
end
