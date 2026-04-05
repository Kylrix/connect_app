class ConnectConfig {
  static const endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://api.kylrix.space/v1',
  );

  static const projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '67fe9627001d97e37ef3',
  );

  static const accountsDomain = String.fromEnvironment(
    'ACCOUNTS_DOMAIN',
    defaultValue: 'https://accounts.kylrix.space',
  );

  static const claimGhostNotesFunction = String.fromEnvironment(
    'CLAIM_GHOST_NOTES_FUNCTION',
    defaultValue: 'claim-ghost-notes',
  );
}
