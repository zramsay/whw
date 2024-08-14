import withPWA from 'next-pwa';

const config = {
  env: {
    CERC_TEST_WEBAPP_CONFIG1: process.env.CERC_TEST_WEBAPP_CONFIG1,
    CERC_TEST_WEBAPP_CONFIG2: process.env.CERC_TEST_WEBAPP_CONFIG2,
    CERC_WEBAPP_DEBUG: process.env.CERC_WEBAPP_DEBUG,
  }
};

const nextConfig = withPWA({ dest: 'public' })(config);

export default nextConfig;
