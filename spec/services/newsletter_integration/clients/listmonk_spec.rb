# frozen_string_literal: true

describe NewsletterIntegration::Clients::Listmonk do
  it "blocks a hostname resolving to a private address before opening a connection" do
    WebMock.enable!(except: [:final_destination])
    FinalDestination::SSRFDetector
      .stubs(:lookup_ips)
      .with("listmonk.example.com", timeout: anything)
      .returns(["127.0.0.1"])
    Socket.expects(:tcp).never
    client =
      described_class.new(
        base_url: "https://listmonk.example.com",
        api_username: "discourse",
        api_token: "a" * 48,
      )

    expect { client.request(verb: "GET", path: "api/subscribers") }.to raise_error(
      NewsletterIntegration::Clients::Listmonk::Error,
      /all resolved IPs were disallowed/,
    )
  ensure
    WebMock.enable!
  end
end
