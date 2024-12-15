import { useRouter } from "next/router";
import type { DocsThemeConfig } from "nextra-theme-docs";
import { Link, useConfig, useThemeConfig } from "nextra-theme-docs";

const hostname = "https://oxideauth-docs.nebuladev.io";

// const logo = (
//   <div className="flex items-center">
//     <img
//       src="/images/logoIcon.png"
//       style={{ width: "50px", height: "50px" }}
//       alt="logo"
//     />
//     <h4>
//       OxideAuth
//     </h4>
//   </div>
// );

const config: DocsThemeConfig = {
  // banner: {
  //   key: "",
  //   content: (
  //     <div></div>
  //   ),
  // },
  project: {
    link: "https://github.com/subaquatic-pierre/oxideauth-api",
  },
  // docsRepositoryBase: "https://github.com/shuding/nextra/tree/main/docs",
  logo: () => {
    const theme = useThemeConfig();
    const config = useConfig();

    // console.log({ theme, config });
    return (
      <div className="flex items-center">
        <img
          src="/images/logoIcon.png"
          style={{ width: "50px", height: "50px" }}
          alt="logo"
        />
        <h2 className="ml-2 font-bold text-lg">OxideAuth Docs</h2>
      </div>
    );
  },
  head: function useHead() {
    const config = useConfig();
    const { route } = useRouter();
    const image = `${hostname}/images/logo.png`;

    const description =
      config.frontMatter.description ||
      "Centralized Microservice Authentication";
    const title = config.title + (route === "/" ? "" : " - OxideAuth");

    return (
      <>
        <title>{title}</title>
        <meta property="og:title" content={title} />
        <meta name="description" content={description} />
        <meta property="og:description" content={description} />
        <meta property="og:image" content={image} />

        <meta name="msapplication-TileColor" content="#fff" />
        <meta httpEquiv="Content-Language" content="en" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:site:domain" content="OxideAuth.site" />
        <meta name="twitter:url" content="https://OxideAuth.site" />
        <meta name="apple-mobile-web-app-title" content="OxideAuth" />
        <link rel="icon" href="/favicon.ico" type="image/icon" />
      </>
    );
  },
  editLink: {
    content: "",
  },
  feedback: {
    content: "",
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true,
  },
  footer: {
    content: (
      <div className="flex w-full flex-col items-center sm:items-start">
        <p className="mt-6 text-xs">© {new Date().getFullYear()} OxideAuth.</p>
      </div>
    ),
  },
};

export default config;
