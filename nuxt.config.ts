// https://nuxt.com/docs/api/configuration/nuxt-config
const repo = process.env.GITHUB_REPOSITORY?.split('/')[1]

export default defineNuxtConfig({
    compatibilityDate: '2025-07-15',
    ssr: false,
    app: {
        baseURL:
            process.env.NODE_ENV === 'production' && repo ? `/${repo}/` : '/',
    },
})
