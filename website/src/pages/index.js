import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';

export default function Home() {
  return (
    <Layout title="Zorphy" description="Modern Dart code generation made approachable">
      <header className="heroBanner">
        <div className="container">
          <h1 className="heroTitle">Zorphy</h1>
          <p className="heroTagline">
            Clean, consistent Dart entities with zero boilerplate. Zorphy generates
            constructors, copyWith, JSON, patch helpers, filters, and polymorphic support
            while keeping your models focused on intent.
          </p>
          <div className="ctaRow">
            <Link className="button button--primary button--lg" to="/docs/features">
              Explore Features
            </Link>
            <Link className="button button--secondary button--lg" to="/docs/examples/basic">
              View Examples
            </Link>
          </div>
        </div>
      </header>
      <main className="container margin-vert--lg">
        <section>
          <h2>What you get out of the box</h2>
          <div className="featureGrid">
            <div className="featureCard">
              <h3>Instant data classes</h3>
              <p>Generated constructors, equality, hashCode, and toString with one annotation.</p>
            </div>
            <div className="featureCard">
              <h3>JSON that fits production</h3>
              <p>Full and lean JSON, converters, defaults, and polymorphic serialization.</p>
            </div>
            <div className="featureCard">
              <h3>Safe updates</h3>
              <p>Patch objects and copyWith helpers make partial updates explicit and composable.</p>
            </div>
            <div className="featureCard">
              <h3>Query-ready fields</h3>
              <p>Filter and sort helpers with in-memory evaluation for fast prototyping.</p>
            </div>
          </div>
        </section>
        <section className="margin-vert--lg">
          <h2>Examples included in the repo</h2>
          <div className="exampleList">
            <div className="exampleItem">Basic entities, copyWith, patch</div>
            <div className="exampleItem">JSON and lean JSON</div>
            <div className="exampleItem">Enums and pattern matching</div>
            <div className="exampleItem">Nested objects and self-references</div>
            <div className="exampleItem">Polymorphic hierarchies</div>
            <div className="exampleItem">Generics with converters</div>
            <div className="exampleItem">Filters, queries, sorting</div>
            <div className="exampleItem">Factories and hidden constructors</div>
            <div className="exampleItem">Defaults, JsonKey, converters</div>
            <div className="exampleItem">Nullability and large hashCode</div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
