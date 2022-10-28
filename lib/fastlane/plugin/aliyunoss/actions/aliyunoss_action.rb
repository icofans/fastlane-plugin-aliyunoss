require 'fastlane/action'
require_relative '../helper/aliyunoss_helper'
require 'aliyun/oss'

module Fastlane
  module Actions
    class AliyunossAction < Action
      def self.run(params)
        UI.message("The aliyunoss plugin is working!")
        
        endpoint = params[:endpoint]
        access_key_id = params[:access_key_id]
        access_key_secret = params[:access_key_secret]
        path_for_app_name = params[:app_name]
        bucket_name = params[:bucket_name]
        list_buckets = params[:list_buckets]

        build_file = params[:apk]
        if build_file.nil?
           UI.user_error!("请提供构建文件")
        end

        UI.message "endpoint: #{endpoint}  bucket_name: #{bucket_name}"
        UI.message "构建文件: #{build_file}"

        download_domain = "https://#{bucket_name}.#{endpoint}/"

         # create aliyun oss client
        client = Aliyun::OSS::Client.new(
            endpoint: endpoint,
            access_key_id: access_key_id,
            access_key_secret: access_key_secret
        )

        bucket = client.get_bucket(bucket_name)

        # list all buckets
        unless list_buckets.nil? || %w(NO no false FALSE).include?(list_buckets) || list_buckets == false
          UI.message "========== list all buckets =========="
          bucket_objects = []
          bucket.list_objects.each do |o|
            UI.message o.key
            bucket_objects.push(o.key)
          end
        end
        UI.message "======================================"

        file_size = File.size(build_file)
        filename = File.basename(build_file)

        # 根据不同的文件类型区分平台，拼接bucket_path路径
        case File.extname(filename)
        when ".apk"
        bucket_path = "#{path_for_app_name}/"
        else
          bucket_path = "#{path_for_app_name}/unknown"
          UI.user_error!("不支持的APP类型")
        end

        if !bucket.object_exists?("#{bucket_path}#{filename}")
            UI.message "正在上传文件，可能需要几分钟，请稍等..."
        else
            UI.message "正在更新文件，可能需要几分钟，请稍等..."
        end

        bucket.put_object(bucket_path + filename, :file => build_file)
        download_url = "#{download_domain}#{bucket_path}#{filename}"
        UI.message "上传成功"
        UI.message "下载链接: #{download_url}"
        UI.message("The aliyunoss plugin done")
      end

      def self.description
        "upload apk to aliyunoss"
      end

      def self.authors
        ["icofans"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "上传apk到阿里云OSS"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :endpoint,
            env_name: "endpoint",
            description: "请提供 endpoint，Endpoint 表示 OSS 对外服务的访问域名。OSS 以 HTTP RESTful API 的形式对外提供服务，当访问不同的 Region 的时候，需要不同的域名。",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :access_key_id,
            env_name: "access_key_id",
            description: "请提供 AccessKeyId，OSS 通过使用 AccessKeyId 和 AccessKeySecret 对称加密的方法来验证某个请求的发送者身份。AccessKeyId 用于标识用户。",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :access_key_secret,
            env_name: "access_key_secret",
            description: "请提供 AccessKeySecret，OSS 通过使用 AccessKeyId 和 AccessKeySecret 对称加密的方法来验证某个请求的发送者身份。AccessKeySecret 是用户用于加密签名字符串和 OSS 用来验证签名字符串的密钥，必须保密。",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :bucket_name,
            env_name: "bucket_name",
            description: "请提供 bucket_name，存储空间（Bucket）是您用于存储对象（Object）的容器，所有的对象都必须隶属于某个存储空间。存储空间具有各种配置属性，包括地域、访问权限、存储类型等。您可以根据实际需求，创建不同类型的存储空间来存储不同的数据。",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :app_name,
            env_name: "app_name",
            description: "App的名称，你的服务器中可能有多个App，需要用App名称来区分，这个名称也是文件目录的名称，可以是App的路径。",
            optional: false),
            FastlaneCore::ConfigItem.new(key: :apk,
                        env_name: "apk",
                        description: "Path to your apk",
                        default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                        optional: true,
                        verify_block: proc do |value|
                          UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                        end),
            FastlaneCore::ConfigItem.new(key: :list_buckets,
                                         env_name: "list_buckets",
                                         description: "是否列出已经上传的所有的buckets",
                                         default_value: nil,
                                         optional: true)

        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios].include?(platform)
        true
      end

      def self.example_code
              [
                  # 上传App到阿里云oss服务器
                  'alioss(
                      endpoint: "oss-cn-shenzhen.aliyuncs.com",
                      access_key_id: "xxxxx",
                      access_key_secret: "xxxxx",
                      bucket_name: "cn-app-test",
                      app_name: "app/appname",
                      apk: "valid apk path" # Android project required
                  )'
              ]
        end

    end
  end
end
