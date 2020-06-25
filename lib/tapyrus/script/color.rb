module Tapyrus
  module Color
    module TokenTypes
      NONE = 0
      REISSUABLE = 1
      NON_REISSUABLE = 2
      NFT = 3
    end

    class ColorIdentifier
      attr_reader :type, :payload

      def self.reissuable(script_pubkey)
        new(TokenTypes::REISSUABLE, Tapyrus.sha256(script_pubkey.to_payload))
      end

      def self.non_reissuable(out_point)
        new(TokenTypes::NON_REISSUABLE, Tapyrus.sha256(out_point.to_payload))
      end

      def self.nft(out_point)
        new(TokenTypes::NFT, Tapyrus.sha256(out_point.to_payload))
      end

      def to_payload
        [type, payload].pack('Ca*')
      end

      def self.parse_from_payload(payload)
        type, payload = payload.unpack('Ca*')
        new(type, payload)
      end

      def ==(other)
        other && other.to_payload == to_payload
      end

      def valid?
        return false unless [TokenTypes::REISSUABLE, TokenTypes::NON_REISSUABLE, TokenTypes::NFT].include?(type)
        return false unless payload.bytesize == 32
        true
      end

      private

      def initialize(type, payload)
        @type = type
        @payload = payload
      end
    end

    module ColoredOutput
      def colored?
        script_pubkey.cp2pkh? || script_pubkey.cp2sh?
      end

      def color_id
        @color_id ||= ColorIdentifier.parse_from_payload(script_pubkey.chunks[0].pushed_data)
      end

      def reissuable?
        return false unless colored?
        color_id.type == TokenTypes::REISSUABLE
      end

      def non_reissuable?
        return false unless colored?
        color_id.type == TokenTypes::NON_REISSUABLE
      end

      def nft?
        return false unless colored?
        color_id.type == TokenTypes::NFT
      end
    end
  end
end
