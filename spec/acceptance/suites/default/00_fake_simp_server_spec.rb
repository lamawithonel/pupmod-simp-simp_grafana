require 'spec_helper_acceptance'

test_name 'fake_simp_server'

simp_server = only_host_with_role(hosts, 'simp_server')

describe 'The fake SIMP server' do
  let(:simp_server_hieradata) { ERB.new(File.read(File.join(FIXTURE_DIR, 'hieradata', 'simp_server.yaml.erb'))).result(binding) }
  let(:simp_server_manifest)  { File.open(File.join(FIXTURE_DIR, 'manifests', 'simp_server.pp')).read }

  it 'installs without errors' do
    set_hieradata_on simp_server, simp_server_hieradata, 'default'

    # We must do this twice before it becomes idempotent due to a bug in
    # pupmod-simp-iptables with SELinux
    apply_manifest_on simp_server, simp_server_manifest, :catch_failures => true
    apply_manifest_on simp_server, simp_server_manifest, :catch_failures => true
  end

  it 'executes Puppet idempotently' do
    apply_manifest_on simp_server, simp_server_manifest, :catch_changes => true
  end

  it 'sets up fake LDAP users and groups' do
    fake_users_and_groups_ldif = File.join(FIXTURE_DIR, 'fake_users_and_groups.ldif')
    scp_to simp_server, fake_users_and_groups_ldif, '/tmp/'
    on simp_server,
       'ldapadd -cZx -D "cn=LDAPAdmin,ou=People,dc=test" -w "123$%^qweRTY" -f /tmp/fake_users_and_groups.ldif',
       :acceptable_exit_codes => [0, 68]
  end
end
