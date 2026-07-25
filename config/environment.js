'use strict';

module.exports = function (environment) {
  const ENV = {
    modulePrefix: 'ec',
    environment,
    rootURL: '/',
    locationType: 'history',
    EmberENV: {
      EXTEND_PROTOTYPES: false,
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    },

    // The single place the API's location is configured.
    //
    // A root-relative path, never an absolute URL. Production behind nginx and
    // development behind Caddy both serve the app and the API from one origin,
    // so a relative path is correct in both and there is no production CORS to
    // configure. Point this elsewhere only if the API is genuinely on another
    // origin, which would also require CORS and SameSite=None cookies.
    apiPath: '/api/v1',

    // Ember Simple Auth's own configuration. The routes below are used by the
    // session service when it redirects after authentication or invalidation.
    'ember-simple-auth': {
      routeAfterAuthentication: 'dashboard',
    },
  };

  if (environment === 'development') {
    // ENV.APP.LOG_RESOLVER = true;
    // ENV.APP.LOG_ACTIVE_GENERATION = true;
    // ENV.APP.LOG_TRANSITIONS = true;
    // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
    // ENV.APP.LOG_VIEW_LOOKUPS = true;
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.locationType = 'none';

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = '#ember-testing';
    ENV.APP.autoboot = false;
  }

  if (environment === 'production') {
    // here you can enable a production-specific feature
  }

  return ENV;
};
